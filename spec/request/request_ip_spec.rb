# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "request IP address determination", type: :request do
  # We inject this RequestIpController to provide our tests with information
  # about the IP address available to Rails controllers
  class RequestIpController < ApplicationController
    def echo
      render json: { ip: request.ip }
    end
  end

  # :reek:UtilityFunction
  def token_auth_header
    # Configure Slosilo to produce valid access tokens
    slosilo = Slosilo["authn:rspec"] ||= Slosilo::Key.new
    bearer_token = slosilo.signed_token('admin')
    "Token token=\"#{Base64.strict_encode64 bearer_token.to_json}\""
  end

  def request_env(remote_addr)
    {
      # We can't modify the access token middleware to add an exception to our
      # test route, so we need to create an access token for our request to use.
      'HTTP_AUTHORIZATION' => token_auth_header,
      'REMOTE_ADDR' => remote_addr
    }
  end

  def request_ip(remote_addr:, x_forwarded_for: nil, trusted_proxies: nil)
    ENV['TRUSTED_PROXIES'] = trusted_proxies if trusted_proxies
  
    headers = {}
    headers['X-Forwarded-For'] = x_forwarded_for if x_forwarded_for
  
    get '/request_ip', env: request_env(remote_addr), headers: headers
  
    JSON.parse(response.body)['ip']
  end

  before do
    # Add the test endpoint to the routes
    Rails.application.routes.draw do
      get '/request_ip' => 'request_ip#echo'
    end
  end

  after do
    # Reset the Conjur routes to remove the test endpoint
    Rails.application.reload_routes!
  end

  # --------------------------------------------------------------------
  # Test Scenarios
  # --------------------------------------------------------------------

  # Without any other configuration in play, we expect to get the remote
  # TCP connection IP address as the request IP address.
  it 'returns the remote_addr with no additional config' do
    expect(request_ip(remote_addr: '44.0.0.1')).to eq('44.0.0.1')
  end

  # When X-Forwarded-For is set from an untrusted remote IP, we ignore it
  it 'ignores the XFF header when the remote addr is untrusted' do
    expect(
      request_ip(
        remote_addr: '44.0.0.1',
        x_forwarded_for: '3.3.3.3'
      )
    ).to eq('44.0.0.1')
  end

  # By default "non-routable" IP addresses are trusted (according to this
  # regular expression: https://github.com/rack/rack/blob/master/lib/rack/request.rb#L19)
  #
  # `127.0.0.1` is important as the address of the nginx proxy when used in DAP
  it 'trusts the loopback address by default to provide XFF' do
    expect(
      request_ip(
        remote_addr: '127.0.0.1',
        x_forwarded_for: '3.3.3.3'
      )
    ).to eq('3.3.3.3')
  end

  # If TRUSTED proxies are set, and are remote IP address is not trusted
  # we expect to get the remote IP
  it "doesn't trust the remote_addr if not included in TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '44.0.0.1',
        x_forwarded_for: '3.3.3.3',
        trusted_proxies: '4.4.4.4'
      )
    ).to eq('44.0.0.1')
  end

  it "trusts 127.0.0.1 for XFF even when not included explicitly with TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '127.0.0.1',
        x_forwarded_for: '3.3.3.3',
        trusted_proxies: '4.4.4.4'
      )
    ).to eq('3.3.3.3')
  end
  
  it "trusts IP ranges for XFF using CIDR notation in TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '5.5.5.1',
        x_forwarded_for: '3.3.3.3',
        trusted_proxies: '5.5.5.0/24'
      )
    ).to eq('3.3.3.3')
  end

  it "returns the expected IP when multiple XFF values are included" do
    expect(
      request_ip(
        remote_addr: '5.5.5.1',
        x_forwarded_for: '3.3.3.3,5.5.5.2,5.5.5.3',
        trusted_proxies: '5.5.5.0/24'
      )
    ).to eq('3.3.3.3')
  end

  it "returns the expected IP when multiple ranges are included in TRUSTED_PROXIES" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,5.5.5.2,5.5.5.3',
        trusted_proxies: '5.5.5.0/24,4.4.4.0/24'
      )
    ).to eq('3.3.3.3')
  end

  it "returns the right-most untrusted IP when XFF contains multiple untrusted IPs" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,6.6.6.6,7.7.7.7',
        trusted_proxies: '4.4.4.0/24'
      )
    ).to eq('7.7.7.7')
  end

  it "returns the right-most untrusted IP when XFF contains some trusted IPs" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,6.6.6.6,5.5.5.5',
        trusted_proxies: '4.4.4.0/24,5.5.5.0/24'
      )
    ).to eq('6.6.6.6')
  end

  it "returns the right-most untrusted IP when XFF contains a trusted IP in the middle" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '3.3.3.3,5.5.5.5,6.6.6.6,7.7.7.7',
        trusted_proxies: '4.4.4.0/24,5.5.5.0/24'
      )
    ).to eq('7.7.7.7')
  end

  it "returns the left-most trusted IP when XFF contains all trusted IPs" do
    expect(
      request_ip(
        remote_addr: '4.4.4.4',
        x_forwarded_for: '5.5.5.5,6.6.6.6',
        trusted_proxies: '4.4.4.4,5.5.5.5,6.6.6.6'
      )
    ).to eq('5.5.5.5')
  end
end
