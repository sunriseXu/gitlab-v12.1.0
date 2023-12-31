require 'fast_spec_helper'
require_dependency 'active_model'

describe EE::Gitlab::Ci::Config::Entry::Trigger do
  subject { described_class.new(config) }

  context 'when trigger config is a non-empty string' do
    let(:config) { 'some/project' }

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#value' do
      it 'is returns a trigger configuration hash' do
        expect(subject.value).to eq(project: 'some/project')
      end
    end
  end

  context 'when trigger config an empty string' do
    let(:config) { '' }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        expect(subject.errors.first)
          .to match /config can't be blank/
      end
    end
  end

  context 'when trigger is a hash' do
    context 'when branch is not provided' do
      let(:config) { { project: 'some/project' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a trigger configuration hash' do
          expect(subject.value).to eq(project: 'some/project')
        end
      end
    end

    context 'when branch is provided' do
      let(:config) { { project: 'some/project', branch: 'feature' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a trigger configuration hash' do
          expect(subject.value)
            .to eq(project: 'some/project', branch: 'feature')
        end
      end
    end

    context 'when config contains unknown keys' do
      let(:config) { { project: 'some/project', unknown: 123 } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about unknown config key' do
          expect(subject.errors.first)
            .to match /config contains unknown keys: unknown/
        end
      end
    end
  end

  context 'when trigger configuration is not valid' do
    context 'when branch is not provided' do
      let(:config) { 123 }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors.first)
            .to match /has to be either a string or a hash/
        end
      end
    end
  end
end
