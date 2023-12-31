# frozen_string_literal: true

module EE
  module Types
    module MutationType
      extend ActiveSupport::Concern

      prepended do
        mount_mutation ::Mutations::DesignManagement::Upload, calls_gitaly: true
      end
    end
  end
end
