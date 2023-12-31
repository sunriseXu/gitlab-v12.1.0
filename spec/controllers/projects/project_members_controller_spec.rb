# frozen_string_literal: true

require('spec_helper')

describe Projects::ProjectMembersController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :access_requestable, namespace: namespace) }
  let(:namespace) { create :group }

  describe 'GET index' do
    it 'has the project_members address with a 200 status code' do
      get :index, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'POST create' do
    let(:project_user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'when user does not have enough rights' do
      before do
        project.add_developer(user)
      end

      it 'returns 404' do
        post :create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        user_ids: project_user.id,
                        access_level: Gitlab::Access::GUEST
                      }

        expect(response).to have_gitlab_http_status(404)
        expect(project.users).not_to include project_user
      end
    end

    context 'when user has enough rights' do
      before do
        project.add_maintainer(user)
      end

      it 'adds user to members' do
        expect_any_instance_of(Members::CreateService).to receive(:execute).and_return(status: :success)

        post :create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        user_ids: project_user.id,
                        access_level: Gitlab::Access::GUEST
                      }

        expect(response).to set_flash.to 'Users were successfully added.'
        expect(response).to redirect_to(project_project_members_path(project))
      end

      it 'adds no user to members' do
        expect_any_instance_of(Members::CreateService).to receive(:execute).and_return(status: :failure, message: 'Message')

        post :create, params: {
                        namespace_id: project.namespace,
                        project_id: project,
                        user_ids: '',
                        access_level: Gitlab::Access::GUEST
                      }

        expect(response).to set_flash.to 'Message'
        expect(response).to redirect_to(project_project_members_path(project))
      end
    end
  end

  describe 'PUT update' do
    let(:requester) { create(:project_member, :access_request, project: project) }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    Gitlab::Access.options.each do |label, value|
      it "can change the access level to #{label}" do
        put :update, params: {
          project_member: { access_level: value },
          namespace_id: project.namespace,
          project_id: project,
          id: requester
        }, xhr: true

        expect(requester.reload.human_access).to eq(label)
      end
    end
  end

  describe 'DELETE destroy' do
    let(:member) { create(:project_member, :developer, project: project) }

    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 404' do
        delete :destroy, params: {
                           namespace_id: project.namespace,
                           project_id: project,
                           id: 42
                         }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          project.add_developer(user)
        end

        it 'returns 404' do
          delete :destroy, params: {
                             namespace_id: project.namespace,
                             project_id: project,
                             id: member
                           }

          expect(response).to have_gitlab_http_status(404)
          expect(project.members).to include member
        end
      end

      context 'when user has enough rights' do
        before do
          project.add_maintainer(user)
        end

        it '[HTML] removes user from members' do
          delete :destroy, params: {
                             namespace_id: project.namespace,
                             project_id: project,
                             id: member
                           }

          expect(response).to redirect_to(
            project_project_members_path(project)
          )
          expect(project.members).not_to include member
        end

        it '[JS] removes user from members' do
          delete :destroy, params: {
            namespace_id: project.namespace,
            project_id: project,
            id: member
          }, xhr: true

          expect(response).to be_success
          expect(project.members).not_to include member
        end
      end
    end
  end

  describe 'DELETE leave' do
    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 404' do
        delete :leave, params: {
                         namespace_id: project.namespace,
                         project_id: project
                       }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when member is found' do
      context 'and is not an owner' do
        before do
          project.add_developer(user)
        end

        it 'removes user from members' do
          delete :leave, params: {
                           namespace_id: project.namespace,
                           project_id: project
                         }

          expect(response).to set_flash.to "You left the \"#{project.human_name}\" project."
          expect(response).to redirect_to(dashboard_projects_path)
          expect(project.users).not_to include user
        end
      end

      context 'and is an owner' do
        let(:project) { create(:project, namespace: user.namespace) }

        before do
          project.add_maintainer(user)
        end

        it 'cannot remove themselves from the project' do
          delete :leave, params: {
                           namespace_id: project.namespace,
                           project_id: project
                         }

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'and is a requester' do
        before do
          project.request_access(user)
        end

        it 'removes user from members' do
          delete :leave, params: {
                           namespace_id: project.namespace,
                           project_id: project
                         }

          expect(response).to set_flash.to 'Your access request to the project has been withdrawn.'
          expect(response).to redirect_to(project_path(project))
          expect(project.requesters).to be_empty
          expect(project.users).not_to include user
        end
      end
    end
  end

  describe 'POST request_access' do
    before do
      sign_in(user)
    end

    it 'creates a new ProjectMember that is not a team member' do
      post :request_access, params: {
                              namespace_id: project.namespace,
                              project_id: project
                            }

      expect(response).to set_flash.to 'Your request for access has been queued for review.'
      expect(response).to redirect_to(
        project_path(project)
      )
      expect(project.requesters.exists?(user_id: user)).to be_truthy
      expect(project.users).not_to include user
    end
  end

  describe 'POST approve' do
    let(:member) { create(:project_member, :access_request, project: project) }

    before do
      sign_in(user)
    end

    context 'when member is not found' do
      it 'returns 404' do
        post :approve_access_request, params: {
                                        namespace_id: project.namespace,
                                        project_id: project,
                                        id: 42
                                      }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when member is found' do
      context 'when user does not have enough rights' do
        before do
          project.add_developer(user)
        end

        it 'returns 404' do
          post :approve_access_request, params: {
                                          namespace_id: project.namespace,
                                          project_id: project,
                                          id: member
                                        }

          expect(response).to have_gitlab_http_status(404)
          expect(project.members).not_to include member
        end
      end

      context 'when user has enough rights' do
        before do
          project.add_maintainer(user)
        end

        it 'adds user to members' do
          post :approve_access_request, params: {
                                          namespace_id: project.namespace,
                                          project_id: project,
                                          id: member
                                        }

          expect(response).to redirect_to(
            project_project_members_path(project)
          )
          expect(project.members).to include member
        end
      end
    end
  end

  describe 'POST apply_import' do
    subject(:apply_import) do
      post(:apply_import, params: {
        namespace_id: project.namespace,
        project_id: project,
        source_project_id: another_project.id
      })
    end
    let(:another_project) { create(:project, :private) }
    let(:member) { create(:user) }

    before do
      project.add_maintainer(user)
      another_project.add_guest(member)
      sign_in(user)
    end

    context 'when user can access source project members' do
      before do
        another_project.add_guest(user)
      end

      it 'imports source project members' do
        apply_import

        expect(project.team_members).to include member
        expect(response).to set_flash.to 'Successfully imported'
        expect(response).to redirect_to(
          project_project_members_path(project)
        )
      end

      context 'and the project group has membership lock enabled' do
        before do
          project.namespace.update(membership_lock: true)
        end

        it 'responds with 403' do
          apply_import

          expect(response.status).to eq 403
        end
      end
    end

    context 'when user is not member of a source project' do
      it 'does not import team members' do
        apply_import

        expect(project.team_members).not_to include member
      end

      it 'responds with not found' do
        apply_import

        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST create' do
    let(:stranger) { create(:user) }
    subject(:create_member) do
      post :create, params: {
        user_ids: stranger.id,
        namespace_id: project.namespace,
        access_level: access_level,
        project_id: project
      }
    end
    let(:access_level) { nil }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'when creating owner' do
      let(:access_level) { Member::OWNER }

      it 'does not create a member' do
        expect { create_member }.not_to change { project.members.count }
      end
    end

    context 'when create maintainer' do
      let(:access_level) { Member::MAINTAINER }

      it 'creates a member' do
        expect { create_member }.to change { project.members.count }.by(1)
      end
    end

    context 'when project group has membership lock enabled' do
      before do
        project.namespace.update(membership_lock: true)
      end

      it 'responds with 403' do
        create_member

        expect(response.status).to eq 403
      end
    end
  end

  describe 'GET import' do
    subject(:import) do
      get :import, params: {
        namespace_id: project.namespace,
        project_id: project
      }
    end

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'responds with 200' do
      import

      expect(response.status).to eq 200
    end

    context 'when project group has membership lock enabled' do
      before do
        project.namespace.update(membership_lock: true)
      end

      it 'responds with 403' do
        import

        expect(response.status).to eq 403
      end
    end
  end
end
