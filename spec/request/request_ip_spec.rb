# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "expected request IP address" do 
  it "uses the expected request IP address" do
    get '/request_ip', env: request_env, headers: headers
    expect(body_hash['ip']).to eq(expected_request_ip)
  end
end

RSpec.describe "request IP address determination", :type => :request do
  # We inject this RequestIpController to provide our tests with information
  # about the IP address available to Rails controllers
  class RequestIpController < ApplicationController
    def echo
      render json: { ip: request.ip }
    end
  end

  before do
    # Add the test endpoint to the routes
    Rails.application.routes.draw do
      get '/request_ip' => 'request_ip#echo'
    end

    # Configure Slosilo to produce valid access tokens
    Slosilo["authn:rspec"] ||= Slosilo::Key.new

    # Set the TRUSTED_PROXIES environment variable for the test
    ENV['TRUSTED_PROXIES'] = trusted_proxies if trusted_proxies
  end

  after do
    # Reset the Conjur routes to remove the test endpoint
    Rails.application.reload_routes!
  end

  # --------------------------------------------------------------------
  # Test Setup
  # --------------------------------------------------------------------

  let(:body_hash) { JSON.parse(response.body) }

  # We can't modify the access token middleware to add an exception to our
  # test route, so we need to create an access token for our request to use.
  let(:bearer_token) { Slosilo["authn:rspec"].signed_token('admin') }
  let(:token_auth_header) do
    "Token token=\"#{Base64.strict_encode64 bearer_token.to_json}\""
  end

  let(:request_env) do
    { 'HTTP_AUTHORIZATION' => token_auth_header, 'REMOTE_ADDR' => remote_ip }
  end

  let(:headers) do
    {}.tap do |h|
      h['X-Forwarded-For'] = x_forwarded_for if x_forwarded_for
    end
  end

  # The value to user for the TRUSTED_PROXIES environment variable
  let(:trusted_proxies) { nil }

  # The value to use for the X-Forwarded-For HTTP header
  let(:x_forwarded_for) { nil }

  # --------------------------------------------------------------------
  # Test Scenarios
  # --------------------------------------------------------------------

  # Without any other configuration in play, we expect to get the remote
  # TCP connection IP address as the request IP address.
  let(:remote_ip) { '44.0.0.1' }
  let(:expected_request_ip) { '44.0.0.1' }
  include_examples "expected request IP address"

  # When X-Forwarded-For is set from an untrusted remote IP, we ignore it
  context 'when X-Forwarded-For is set' do
    let(:x_forwarded_for) { '3.3.3.3' }
    let(:expected_request_ip) { '44.0.0.1' }
    include_examples "expected request IP address"

    # Loopback is a default trusted IP, so we accept the forwarded address
    context 'when remote IP is loopback' do
      let(:remote_ip) { '127.0.0.1' }
      let(:expected_request_ip) { '3.3.3.3' }
      include_examples "expected request IP address"
    end
  end

  context 'when TRUSTED_PROXIES is set' do
    # If TRUSTED proxies are set, and are remote IP address is not trusted
    # we expect to get the remote IP
    let(:trusted_proxies) { '4.4.4.4,5.5.5.5' }
    let(:expected_request_ip) { '44.0.0.1' }
    include_examples "expected request IP address"

    context 'when remote IP is loopback' do
      let(:remote_ip) { '127.0.0.1' }
      let(:expected_request_ip) { '127.0.0.1' }
      include_examples "expected request IP address"

      # Loopback is always trusted, even if not explicity provided in
      # TRUSTED_PROXIES, so we accept the forwarded IP address.
      context 'when X-Forwarded-For is set' do
        let(:x_forwarded_for) { '3.3.3.3' }
        let(:expected_request_ip) { '3.3.3.3' }
        include_examples "expected request IP address"
      end
    end

    context 'when using CIDR notation for trusted IP ranges' do
      let(:trusted_proxies) { '5.5.5.0/24' }
      let(:remote_ip) { '5.5.5.1' }
      let(:x_forwarded_for) { '3.3.3.3,5.5.5.2,5.5.5.3' }
      let(:expected_request_ip) { '3.3.3.3' }
      include_examples "expected request IP address"

      context 'when multiple IP ranges are trusted' do
        let(:trusted_proxies) { '4.4.4.0/24,5.5.5.0/24' }
        let(:remote_ip) { '5.5.5.1' }
        let(:x_forwarded_for) { '3.3.3.3,4.4.4.1,5.5.5.3' }
        let(:expected_request_ip) { '3.3.3.3' }
        include_examples "expected request IP address"
      end
    end

    # The following spec exercise how variations on the X-Forwarded-For header
    # trusted proxies translate into the final IP address for the Rails request.
    context 'when remote IP is trusted' do
      let(:remote_ip) { '4.4.4.4' }
      let(:expected_request_ip) { '4.4.4.4' }
      include_examples "expected request IP address"

      context 'when X-Forwarded-For is set' do
        let(:x_forwarded_for) { '3.3.3.3' }
        let(:expected_request_ip) { '3.3.3.3' }
        include_examples "expected request IP address"
      end

      context 'when X-Forwarded-For contains multiple untrusted IPs' do
        let(:x_forwarded_for) { '3.3.3.3,6.6.6.6,7.7.7.7' }
        # it returns the right-most
        let(:expected_request_ip) { '7.7.7.7' }
        include_examples "expected request IP address"
      end

      context 'when X-Forwarded-For contains some trusted IPs' do
        let(:x_forwarded_for) { '3.3.3.3, 5.5.5.5' }
        # it returns the right-most untrusted value
        let(:expected_request_ip) { '3.3.3.3' }
        include_examples "expected request IP address"
      end

      context 'when X-Forwarded-For contains multiple untrusted IPs' do
        let(:x_forwarded_for) { '3.3.3.3,6.6.6.6,7.7.7.7,5.5.5.5' }
        # it returns the right-most untrusted value
        let(:expected_request_ip) { '7.7.7.7' }
        include_examples "expected request IP address"
      end

      context 'when X-Forwarded-For contains some trusted IP in the middle' do
        let(:x_forwarded_for) { '3.3.3.3,5.5.5.5,6.6.6.6,7.7.7.7' }
        # it returns the right-most untrusted value
        let(:expected_request_ip) { '7.7.7.7' }
        include_examples "expected request IP address"
      end

      context 'when X-Forwarded-For contains all trusted IPs' do
        let(:trusted_proxies) { '4.4.4.4,5.5.5.5,6.6.6.6' }
        let(:x_forwarded_for) { '5.5.5.5,6.6.6.6' }
        # it returns the left-most trusted value
        let(:expected_request_ip) { '5.5.5.5' }
        include_examples "expected request IP address"
      end
    end
  end
end
