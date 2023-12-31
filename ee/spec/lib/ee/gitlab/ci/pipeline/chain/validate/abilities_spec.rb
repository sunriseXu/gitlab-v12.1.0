# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Validate::Abilities do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:pipeline) do
    build_stubbed(:ci_pipeline, project: project)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command
      .new(project: project, current_user: user, origin_ref: ref)
  end

  let(:step) { described_class.new(pipeline, command) }
  let(:ref) { 'master' }

  describe '#perform!' do
    context 'when triggering builds for project mirrors is disabled' do
      it 'returns an error' do
        project.add_developer(user)

        allow(command)
          .to receive(:allow_mirror_update)
          .and_return(true)

        allow(project)
          .to receive(:mirror_trigger_builds?)
          .and_return(false)

        step.perform!

        expect(pipeline.errors.to_a)
          .to include('Pipeline is disabled for mirror updates')
      end
    end
  end
end
