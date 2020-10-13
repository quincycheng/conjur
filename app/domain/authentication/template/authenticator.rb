require 'command_class'

module Authentication
  # TODO: Change the module name to your authenticator name (e.g AuthnK8s)
  module AuthnTemplate

    Authenticator = CommandClass.new(
      # TODO: Add any dependencies required by this class
      dependencies: {

      },
      # 'authenticator_input' should be the only input parameter
      inputs:       [:authenticator_input]
    ) do

      # TODO: Remove the '@authenticator_input' fields that are not needed in this class
      extend Forwardable
      def_delegators(
        :@authenticator_input, :authenticator_name, :service_id, :account,
        :username, :credentials, :client_ip, :request, :webservice, :role
      )

      # TODO: Add calls to the private methods so tha the 'call' method tells the
      # story of this class
      def call

      end

      # TODO: Add any private methods required by this class. 'call' should be
      # the only public method of this class.
      private

    end

    class Authenticator
      # This delegates to all the work to the call method created automatically
      # by CommandClass
      #
      # This is needed because we need `valid?` to exist on the Authenticator
      # class, but that class contains only a metaprogramming generated
      # `call(authenticator_input:)` method.  The methods we define in the
      # block passed to `CommandClass` exist only on the private internal
      # `Call` objects created each time `call` is run.
      def valid?(input)
        call(authenticator_input: input)
      end

      def status(authenticator_status_input:)
        # TODO: change the module name to your authenticator name (e.g AuthnK8s)
        # TODO: Pass any field of 'authenticator_status_input' that is required
        # in your 'ValidateStatus' class. The available fields are:
        #   - authenticator_name
        #   - service_id
        #   - account
        #   - username
        #   - client_ip
        #   - webservice
        #   - status_webservice
        #   - role
        Authentication::AuthnTemplate::ValidateStatus.new.call
      end
    end
  end
end
