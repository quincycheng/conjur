# frozen_string_literal: true
  
# Responsible for creating policy. Called when a POST request is received
module Loader
  class CreatePolicy
    def initialize(loader)
      @loader = loader
    end

    def self.from_policy(policy_version, context: {})
      CreatePolicy.new(Loader::Orchestrate.new(policy_version, context: context))
    end

    def call
      @loader.setup_db_for_new_policy

      @loader.delete_shadowed_and_duplicate_rows

      @loader.store_policy_in_db
    end

    def new_roles
      @loader.new_roles
    end
  end
end
