# frozen_string_literal: true

class Groups::ScimOauthController < Groups::ApplicationController
  include SamlAuthorization

  before_action :require_top_level_group
  before_action :authorize_manage_saml!
  before_action :check_group_saml_available!
  before_action :check_group_saml_configured
  before_action :check_group_scim_enabled

  def show
    scim_token = ScimOauthAccessToken.find_by_group_id(@group.id)

    respond_to do |format|
      format.json do
        if scim_token
          render json: scim_token.as_entity_json
        else
          render json: {}
        end
      end
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def create
    scim_token = ScimOauthAccessToken.find_or_initialize_by(group: @group)

    if scim_token.new_record?
      scim_token.save
    else
      scim_token.reset_token!
    end

    respond_to do |format|
      format.json do
        if scim_token.valid?
          render json: scim_token.as_entity_json
        else
          render json: { errors: scim_token.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def check_group_scim_enabled
    route_not_found unless Feature.enabled?(:group_scim, @group)
  end
end
