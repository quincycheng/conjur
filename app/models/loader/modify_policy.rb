# frozen_string_literal: true

# Responsible for modifying policy. Called when a PATCH request is received
module Loader
  class ModifyPolicy
    def initialize(loader)
      @loader = loader
    end

    def self.from_policy(policy_version, context:)
      ModifyPolicy.new(Loader::Orchestrate.new(policy_version, context: context))
    end

    def call
      @loader.setup_db_for_new_policy
      
      @loader.delete_shadowed_and_duplicate_rows

      @loader.update_changed

      @loader.store_policy_in_db
    end

    def new_roles
      @loader.new_roles
    end
  end
end
