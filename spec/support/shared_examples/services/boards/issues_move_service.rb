shared_examples 'issues move service' do |group|
  shared_examples 'updating timestamps' do
    it 'updates updated_at' do
      expect {described_class.new(parent, user, params).execute(issue)}
        .to change {issue.reload.updated_at}
    end
  end

  context 'when moving an issue between lists' do
    let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development]) }
    let(:params) { { board_id: board1.id, from_list_id: list1.id, to_list_id: list2.id } }

    it_behaves_like 'updating timestamps'

    it 'delegates the label changes to Issues::UpdateService' do
      service = double(:service)
      expect(Issues::UpdateService).to receive(:new).and_return(service)
      expect(service).to receive(:execute).with(issue).once

      described_class.new(parent, user, params).execute(issue)
    end

    it 'removes the label from the list it came from and adds the label of the list it goes to' do
      described_class.new(parent, user, params).execute(issue)

      expect(issue.reload.labels).to contain_exactly(bug, testing)
    end
  end

  context 'when moving to closed' do
    let!(:list3) { create(:list, board: board2, label: regression, position: 1) }

    let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development, testing, regression]) }
    let(:params) { { board_id: board1.id, from_list_id: list2.id, to_list_id: closed.id } }

    it_behaves_like 'updating timestamps'

    it 'delegates the close proceedings to Issues::CloseService' do
      expect_any_instance_of(Issues::CloseService).to receive(:execute).with(issue).once

      described_class.new(parent, user, params).execute(issue)
    end

    it 'removes all list-labels from boards and close the issue' do
      described_class.new(parent, user, params).execute(issue)
      issue.reload

      expect(issue.labels).to contain_exactly(bug, regression)
      expect(issue).to be_closed
    end
  end

  context 'when moving to backlog' do
    let(:milestone) { create(:milestone, project: project) }
    let!(:backlog)  { create(:backlog_list, board: board1) }

    let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development, testing, regression], milestone: milestone) }
    let(:params) { { board_id: board1.id, from_list_id: list2.id, to_list_id: backlog.id } }

    it_behaves_like 'updating timestamps'

    it 'keeps labels and milestone' do
      described_class.new(parent, user, params).execute(issue)
      issue.reload

      expect(issue.labels).to contain_exactly(bug, regression)
      expect(issue.milestone).to eq(milestone)
    end
  end

  context 'when moving from closed' do
    let(:issue)  { create(:labeled_issue, :closed, project: project, labels: [bug]) }
    let(:params) { { board_id: board1.id, from_list_id: closed.id, to_list_id: list2.id } }

    it_behaves_like 'updating timestamps'

    it 'delegates the re-open proceedings to Issues::ReopenService' do
      expect_any_instance_of(Issues::ReopenService).to receive(:execute).with(issue).once

      described_class.new(parent, user, params).execute(issue)
    end

    it 'adds the label of the list it goes to and reopen the issue' do
      described_class.new(parent, user, params).execute(issue)
      issue.reload

      expect(issue.labels).to contain_exactly(bug, testing)
      expect(issue).to be_opened
    end
  end

  context 'when moving to same list' do
    let(:assignee) { create(:user) }
    let(:params)   { { board_id: board1.id, from_list_id: list1.id, to_list_id: list1.id } }
    let(:issue1)   { create(:labeled_issue, project: project, labels: [bug, development]) }
    let(:issue2)   { create(:labeled_issue, project: project, labels: [bug, development]) }
    let(:issue) do
      create(:labeled_issue, project: project, labels: [bug, development], assignees: [assignee])
    end

    it 'returns false' do
      expect(described_class.new(parent, user, params).execute(issue)).to eq false
    end

    it 'keeps issues labels' do
      described_class.new(parent, user, params).execute(issue)

      expect(issue.reload.labels).to contain_exactly(bug, development)
    end

    it 'keeps issues assignees' do
      described_class.new(parent, user, params).execute(issue)

      expect(issue.reload.assignees).to contain_exactly(assignee)
    end

    it 'sorts issues' do
      reorder_issues(params, issues: [issue, issue1, issue2])

      described_class.new(parent, user, params).execute(issue)

      expect(issue.relative_position).to be_between(issue1.relative_position, issue2.relative_position)
    end

    it 'does not update updated_at' do
      reorder_issues(params, issues: [issue, issue1, issue2])

      updated_at = issue.updated_at
      updated_at1 = issue1.updated_at
      updated_at2 = issue2.updated_at

      Timecop.travel(1.minute.from_now) do
        described_class.new(parent, user, params).execute(issue)
      end

      expect(issue.reload.updated_at.change(usec: 0)).to eq updated_at.change(usec: 0)
      expect(issue1.reload.updated_at.change(usec: 0)).to eq updated_at1.change(usec: 0)
      expect(issue2.reload.updated_at.change(usec: 0)).to eq updated_at2.change(usec: 0)
    end

    if group
      context 'when on a group board' do
        it 'sends the board_group_id parameter' do
          params.merge!(move_after_id: issue1.id, move_before_id: issue2.id)

          match_params = { move_between_ids: [issue1.id, issue2.id], board_group_id: parent.id }
          expect(Issues::UpdateService).to receive(:new).with(issue.project, user, match_params).and_return(double(execute: build(:issue)))

          described_class.new(parent, user, params).execute(issue)
        end
      end
    end

    def reorder_issues(params, issues: [])
      issues.each do |issue|
        issue.move_to_end && issue.save!
      end

      params.merge!(move_after_id: issues[1].id, move_before_id: issues[2].id)
    end
  end
end
