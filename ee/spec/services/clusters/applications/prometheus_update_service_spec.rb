# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::PrometheusUpdateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:cluster) { create(:cluster, :provided_by_user, :with_installed_helm, projects: [project]) }
    let(:application) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }
    let(:values_yaml) { application.values }
    let!(:upgrade_command) { application.upgrade_command('') }
    let(:helm_client) { instance_double(::Gitlab::Kubernetes::Helm::Api) }

    subject(:service) { described_class.new(application, project) }

    before do
      allow(service).to receive(:upgrade_command).and_return(upgrade_command)
      allow(service).to receive(:helm_api).and_return(helm_client)
    end

    context 'when there are no errors' do
      before do
        expect(helm_client).to receive(:update).with(upgrade_command)

        allow(::ClusterWaitForAppUpdateWorker)
          .to receive(:perform_in)
          .and_return(nil)
      end

      it 'make the application updating' do
        expect(application.cluster).not_to be_nil

        service.execute

        expect(application).to be_updating
      end

      it 'updates current config' do
        prometheus_config_service = spy(:prometheus_config_service)
        values = YAML.safe_load(values_yaml)

        expect(Clusters::Applications::PrometheusConfigService)
          .to receive(:new)
          .with(project, cluster, application)
          .and_return(prometheus_config_service)

        expect(prometheus_config_service)
          .to receive(:execute)
          .with(values)

        service.execute
      end

      it 'schedules async update status check' do
        expect(::ClusterWaitForAppUpdateWorker).to receive(:perform_in).once

        service.execute
      end
    end

    context 'when k8s cluster communication fails' do
      before do
        error = ::Kubeclient::HttpError.new(500, 'system failure', nil)
        allow(helm_client).to receive(:update).and_raise(error)
      end

      it 'make the application update errored' do
        service.execute

        expect(application).to be_update_errored
        expect(application.status_reason).to match(/kubernetes error:/i)
      end
    end

    context 'when application cannot be persisted' do
      let(:application) { build(:clusters_applications_prometheus, :installed) }

      before do
        allow(application).to receive(:make_updating!).once
          .and_raise(ActiveRecord::RecordInvalid.new(application))
      end

      it 'make the application update errored' do
        expect(helm_client).not_to receive(:update)

        service.execute

        expect(application).to be_update_errored
      end
    end
  end
end
