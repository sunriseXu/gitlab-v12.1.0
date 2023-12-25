# frozen_string_literal: true

require 'spec_helper'

describe ProjectsFinder do
  describe '#execute' do
    subject { finder.execute }

    let(:user) { create(:user) }

    describe 'filter by plans' do
      let!(:gold_project) { create_project(:gold_plan) }
      let!(:gold_project2) { create_project(:gold_plan) }
      let!(:silver_project) { create_project(:silver_plan) }
      let!(:no_plan_project) { create_project(nil) }

      let(:finder) { described_class.new(params: { plans: plans }) }

      context 'with gold plan' do
        let(:plans) { ['gold'] }

        it { is_expected.to contain_exactly(gold_project, gold_project2) }
      end

      context 'with multiple plans' do
        let(:plans) { %w[gold silver] }

        it { is_expected.to contain_exactly(gold_project, gold_project2, silver_project) }
      end

      context 'with other plans' do
        let(:plans) { ['bronze'] }

        it { is_expected.to be_empty }
      end

      context 'without plans' do
        let(:plans) { nil }

        it { is_expected.to contain_exactly(gold_project, gold_project2, silver_project, no_plan_project) }
      end

      context 'with empty plans' do
        let(:plans) { [] }

        it { is_expected.to contain_exactly(gold_project, gold_project2, silver_project, no_plan_project) }
      end

      private

      def create_project(plan)
        create(:project, :public, namespace: create(:namespace, plan: plan))
      end
    end
  end
end
