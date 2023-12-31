# frozen_string_literal: true

module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      respond_to :json

      protect_from_forgery except: [:notify]

      skip_before_action :project, only: [:notify]

      prepend_before_action :repository, :project_without_auth, only: [:notify]

      before_action :authorize_read_prometheus_alerts!, except: [:notify]
      before_action :alert, only: [:update, :show, :destroy]

      def index
        render json: serialize_as_json(alerts)
      end

      def show
        render json: serialize_as_json(alert)
      end

      def notify
        token = extract_alert_manager_token(request)

        if notify_service.execute(token)
          head :ok
        else
          head :unprocessable_entity
        end
      end

      def create
        @alert = create_service.execute

        if @alert.persisted?
          schedule_prometheus_update!

          render json: serialize_as_json(@alert)
        else
          head :no_content
        end
      end

      def update
        if update_service.execute(alert)
          schedule_prometheus_update!

          render json: serialize_as_json(alert)
        else
          head :no_content
        end
      end

      def destroy
        if destroy_service.execute(alert)
          schedule_prometheus_update!

          head :ok
        else
          head :no_content
        end
      end

      private

      def alerts_params
        params.permit(:operator, :threshold, :environment_id, :prometheus_metric_id)
      end

      def notify_service
        Projects::Prometheus::Alerts::NotifyService
          .new(project, current_user, params.permit!)
      end

      def create_service
        Projects::Prometheus::Alerts::CreateService
          .new(project, current_user, alerts_params)
      end

      def update_service
        Projects::Prometheus::Alerts::UpdateService
          .new(project, current_user, alerts_params)
      end

      def destroy_service
        Projects::Prometheus::Alerts::DestroyService
          .new(project, current_user, nil)
      end

      def schedule_prometheus_update!
        ::Clusters::Applications::ScheduleUpdateService.new(application, project).execute
      end

      def serialize_as_json(alert_obj)
        serializer.represent(alert_obj)
      end

      def serializer
        PrometheusAlertSerializer
          .new(project: project, current_user: current_user)
      end

      def alerts
        alerts_finder.execute
      end

      def alert
        @alert ||= alerts_finder(metric: params[:id]).execute.first || render_404
      end

      def alerts_finder(opts = {})
        Projects::Prometheus::AlertsFinder.new({
          project: project,
          environment: params[:environment_id]
        }.reverse_merge(opts))
      end

      def application
        @application ||= alert.environment.cluster_prometheus_adapter
      end

      def extract_alert_manager_token(request)
        Doorkeeper::OAuth::Token.from_bearer_authorization(request)
      end

      def project_without_auth
        return @project if @project

        namespace = params[:namespace_id]
        id = params[:project_id]

        @project = Project.find_by_full_path("#{namespace}/#{id}")
      end

      def prometheus_alerts
        project.prometheus_alerts.for_environment(params[:environment_id])
      end
    end
  end
end
