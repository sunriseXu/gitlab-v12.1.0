# frozen_string_literal: true

module Keys
  class CreateService < ::Keys::BaseService
    def execute
      key = user.keys.create(params)
      notification_service.new_key(key) if key.persisted?
      key
    end
  end
end

Keys::CreateService.prepend(EE::Keys::CreateService)
