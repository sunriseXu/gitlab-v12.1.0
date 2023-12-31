# frozen_string_literal: true

require 'spec_helper'

describe LabelNote do
  include Gitlab::Routing.url_helpers

  set(:group)  { create(:group) }
  set(:user)   { create(:user) }
  set(:label) { create(:group_label, group: group) }
  set(:label2) { create(:group_label, group: group) }
  let(:resource_parent) { group }
  set(:resource) { create(:epic, group: group) }
  let(:project) { nil }
  let(:resource_key) { resource.class.name.underscore.to_s }
  let(:events) { [create(:resource_label_event, label: label, resource_key => resource)] }

  subject { described_class.from_events(events) }

  context 'when resource is epic' do
    it_behaves_like 'label note created from events'

    it 'includes a link to the list of epics filtered by the label' do
      expect(subject.note_html).to include(group_epics_path(group, label_name: label.title))
    end
  end

  context 'when a label is removed' do
    it 'returns note correctly' do
      events
      label.destroy
      events.first.reload

      expect(subject.note).to include('deleted label')
    end
  end
end
