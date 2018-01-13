# frozen_string_literal: true

RSpec.describe ProjectsController, type: :controller do
  context 'unauthenticated' do
    describe 'GET #show' do
      before { get :show, params: { company_id: 'xpto', customer_id: 'bar', id: 'foo' } }
      it { expect(response).to redirect_to new_user_session_path }
    end
    describe 'GET #index' do
      before { get :index, params: { company_id: 'xpto', customer_id: 'bar' } }
      it { expect(response).to redirect_to new_user_session_path }
    end
  end

  context 'authenticated' do
    let(:user) { Fabricate :user }
    before { sign_in user }

    describe 'GET #show' do
      let(:company) { Fabricate :company, users: [user] }
      let(:customer) { Fabricate :customer, company: company, name: 'zzz' }
      let!(:first_project) { Fabricate :project, customer: customer, end_date: 5.days.from_now }
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: 1.day.ago }
      let!(:second_result) { Fabricate :project_result, project: first_project, result_date: 2.days.ago }

      context 'passing valid IDs' do
        before { get :show, params: { company_id: company, customer_id: customer, id: first_project } }
        it 'assigns the instance variable and renders the template' do
          expect(response).to render_template :show
          expect(assigns(:company)).to eq company
          expect(assigns(:project)).to eq first_project
          expect(assigns(:project_results)).to eq [second_result, first_result]
          expect(assigns(:total_hours_upstream)).to eq first_result.qty_hours_upstream + second_result.qty_hours_upstream
          expect(assigns(:total_hours_downstream)).to eq first_result.qty_hours_downstream + second_result.qty_hours_downstream
          expect(assigns(:total_hours)).to eq first_result.total_hours_consumed + second_result.total_hours_consumed
          expect(assigns(:total_throughput)).to eq first_result.throughput + second_result.throughput
          expect(assigns(:total_bugs_opened)).to eq first_result.qty_bugs_opened + second_result.qty_bugs_opened
          expect(assigns(:total_bugs_closed)).to eq first_result.qty_bugs_closed + second_result.qty_bugs_closed
          expect(assigns(:total_hours_bug)).to eq first_result.qty_hours_bug + second_result.qty_hours_bug
          expect(assigns(:avg_leadtime)).to eq((first_result.leadtime + second_result.leadtime) / 2)
        end
      end
      context 'passing an invalid ID' do
        context 'non-existent' do
          before { get :show, params: { company_id: company, customer_id: customer, id: 'foo' } }
          it { expect(response).to have_http_status :not_found }
        end
        context 'not permitted' do
          let(:company) { Fabricate :company, users: [] }
          before { get :show, params: { company_id: company, customer_id: customer, id: first_project } }
          it { expect(response).to have_http_status :not_found }
        end
      end
    end

    describe 'GET #index' do
      context 'not passing status filter' do
        let(:company) { Fabricate :company, users: [user] }
        let(:customer) { Fabricate :customer, company: company }
        let!(:project) { Fabricate :project, customer: customer, end_date: 2.days.from_now }
        let!(:other_project) { Fabricate :project, customer: customer, end_date: 5.days.from_now }
        let!(:other_company_project) { Fabricate :project, end_date: 2.days.from_now }
        before { get :index, params: { company_id: company } }
        it 'assigns the instance variable and renders the template' do
          expect(response).to render_template :index
          projects = assigns(:projects)
          expect(projects).to eq [other_project, project]
          expect(assigns(:total_hours)).to eq projects.sum(&:qty_hours)
          expect(assigns(:average_hour_value)).to eq projects.average(:hour_value)
          expect(assigns(:total_value)).to eq projects.sum(:value)
        end
      end
      context 'passing status filter' do
        let(:company) { Fabricate :company, users: [user] }
        let(:customer) { Fabricate :customer, company: company }
        let!(:project) { Fabricate :project, customer: customer, status: :executing }
        let!(:other_project) { Fabricate :project, customer: customer, status: :waiting }
        let!(:other_company_project) { Fabricate :project, status: :executing }
        before { get :index, params: { company_id: company, status_filter: :executing } }
        it 'assigns the instance variable and renders the template' do
          expect(response).to render_template :index
          expect(assigns(:projects)).to eq [project]
        end
      end
    end
  end
end