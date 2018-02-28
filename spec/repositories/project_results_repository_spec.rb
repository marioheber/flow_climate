# frozen_string_literal: true

RSpec.describe ProjectResultsRepository, type: :repository do
  let(:company) { Fabricate :company }
  let(:customer) { Fabricate :customer, company: company }
  let(:product) { Fabricate :product, customer: customer, name: 'zzz' }

  let!(:first_project) { Fabricate :project, customer: customer, product: product, start_date: Time.iso8601('2018-01-03T23:01:46'), end_date: Time.iso8601('2018-03-16T23:01:46') }
  let!(:second_project) { Fabricate :project, customer: customer, product: product, start_date: Time.iso8601('2018-01-10T23:01:46'), end_date: Time.iso8601('2018-03-16T23:01:46') }
  let!(:third_project) { Fabricate :project, customer: customer, product: product, start_date: Time.iso8601('2018-01-04T23:01:46'), end_date: Time.iso8601('2018-03-16T23:01:46') }

  let!(:stage) { Fabricate :stage, projects: [first_project], integration_id: '2481595', compute_effort: true }
  let!(:end_stage) { Fabricate :stage, projects: [first_project], integration_id: '2481597', compute_effort: false, end_point: true }

  describe '#project_results_for_company_month' do
    let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-01-14T23:01:46'), qty_hours_downstream: 30 }
    let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_hours_downstream: 50 }
    let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), qty_hours_downstream: 90 }
    let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_hours_downstream: 60 }

    it { expect(ProjectResultsRepository.instance.project_results_for_company_month(company, Time.iso8601('2018-02-14T23:01:46'))).to match_array [second_result, third_result] }
  end

  describe '#consumed_hours_in_month' do
    let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-01-14T23:01:46'), qty_hours_upstream: 0, qty_hours_downstream: 30 }
    let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_hours_upstream: 0, qty_hours_downstream: 50 }
    let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), qty_hours_upstream: 0, qty_hours_downstream: 90 }
    let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_hours_downstream: 60 }

    it { expect(ProjectResultsRepository.instance.consumed_hours_in_month(company, Time.iso8601('2018-02-14T23:01:46').to_date)).to eq 140 }
  end

  describe '#consumed_hours_in_month' do
    let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-01-14T23:01:46'), qty_hours_upstream: 0, qty_hours_downstream: 30 }
    let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_hours_upstream: 0, qty_hours_downstream: 50 }
    let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), qty_hours_upstream: 0, qty_hours_downstream: 90 }
    let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_hours_downstream: 60 }

    it { expect(ProjectResultsRepository.instance.consumed_hours_in_month(company, Time.iso8601('2018-02-14T23:01:46'))).to eq 140 }
  end

  describe '#throughput_in_month_for_company' do
    let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-01-14T23:01:46'), throughput: 30 }
    let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-14T23:01:46'), throughput: 50 }
    let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), throughput: 90 }
    let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), throughput: 60 }

    it { expect(ProjectResultsRepository.instance.throughput_in_month_for_company(company, Time.iso8601('2018-02-14T23:01:46'))).to eq 140 }
  end

  describe '#throughput_in_month_for_company' do
    let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-01-14T23:01:46'), throughput: 30 }
    let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-14T23:01:46'), throughput: 50 }
    let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), throughput: 90 }
    let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), throughput: 60 }

    it { expect(ProjectResultsRepository.instance.throughput_in_month_for_company(company, Time.iso8601('2018-02-14T23:01:46').to_date)).to eq 140 }
  end

  describe '#bugs_opened_in_month' do
    let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-01-14T23:01:46'), qty_bugs_opened: 30 }
    let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_bugs_opened: 50 }
    let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), qty_bugs_opened: 90 }
    let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_bugs_opened: 60 }

    it { expect(ProjectResultsRepository.instance.bugs_opened_in_month(company, Time.iso8601('2018-02-14T23:01:46').to_date)).to eq 140 }
  end

  describe '#bugs_closed_in_month' do
    let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-01-14T23:01:46'), qty_bugs_closed: 30 }
    let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_bugs_closed: 50 }
    let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), qty_bugs_closed: 90 }
    let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_bugs_closed: 60 }

    it { expect(ProjectResultsRepository.instance.bugs_closed_in_month(company, Time.iso8601('2018-02-14T23:01:46').to_date)).to eq 140 }
  end

  describe '#scope_in_week_for_project' do
    context 'when there is data in the week' do
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-02-16T23:01:46') }
      let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-15T23:01:46') }
      let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46') }
      let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_bugs_closed: 60 }

      it { expect(ProjectResultsRepository.instance.scope_in_week_for_projects([first_project], Time.iso8601('2018-02-14T23:01:46').to_date.cweek, Time.iso8601('2018-02-14T23:01:46').to_date.cwyear)).to eq first_result.known_scope }
    end
    context 'when there is no data in the week but there is in past weeks' do
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-02-11T23:01:46') }
      let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), qty_bugs_closed: 60 }

      it { expect(ProjectResultsRepository.instance.scope_in_week_for_projects([first_project], Time.iso8601('2018-02-15T23:01:46').to_date.cweek, Time.iso8601('2018-02-15T23:01:46').to_date.cwyear)).to eq first_result.known_scope }
    end
    context 'when there is no data' do
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-02-16T23:01:46'), known_scope: 30 }
      let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-03-25T23:01:46'), qty_bugs_closed: 60 }

      it { expect(ProjectResultsRepository.instance.scope_in_week_for_projects([first_project], Time.iso8601('2018-02-15T23:01:46').to_date.cweek, Time.iso8601('2018-02-15T23:01:46').to_date.cwyear)).to eq first_project.initial_scope }
    end
  end

  describe '#flow_pressure_in_week_for_projects' do
    context 'when there is data in the week' do
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-02-16T23:01:46'), flow_pressure: 20 }
      let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-15T23:01:46'), flow_pressure: 10 }
      let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), flow_pressure: 5 }
      let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), flow_pressure: 4 }

      it { expect(ProjectResultsRepository.instance.flow_pressure_in_week_for_projects([first_project])).to eq(Time.iso8601('2018-02-16T23:01:46').localtime(0).change(hour: 0).beginning_of_week => 0.2e2) }
    end
    context 'when there is no data' do
      let!(:project) { Fabricate :project, customer: customer, product: product, start_date: 1.month.ago, end_date: 1.month.from_now }

      it { expect(ProjectResultsRepository.instance.flow_pressure_in_week_for_projects([project])).to eq({}) }
    end
  end

  describe '#throughput_for_projects_grouped_per_week' do
    context 'when there is data in the week' do
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-02-16T23:01:46'), throughput: 20 }
      let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-15T23:01:46'), throughput: 10 }
      let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), throughput: 5 }
      let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), flow_pressure: 4 }

      it { expect(ProjectResultsRepository.instance.throughput_for_projects_grouped_per_week([first_project, second_project])).to eq(Time.iso8601('2018-02-16T23:01:46-00:00').change(hour: 0).beginning_of_week => 30) }
    end
    context 'when there is no data' do
      let!(:project) { Fabricate :project, customer: customer, product: product, start_date: 1.month.ago, end_date: 1.month.from_now }

      it { expect(ProjectResultsRepository.instance.throughput_for_projects_grouped_per_week([project])).to eq({}) }
    end
  end

  describe '#hours_per_demand_in_time_for_projects' do
    let(:team) { Fabricate :team }
    let!(:team_member) { Fabricate :team_member, team: team, monthly_payment: 100 }
    let!(:other_team_member) { Fabricate :team_member, team: team, monthly_payment: 100 }

    context 'when there is data in the week' do
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-02-16T23:01:46'), throughput: 20, qty_hours_downstream: 20, qty_hours_upstream: 11 }
      let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-16T23:01:46'), throughput: 10, qty_hours_downstream: 20, qty_hours_upstream: 11 }
      let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), throughput: 5, qty_hours_downstream: 20, qty_hours_upstream: 11 }
      let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), flow_pressure: 4 }

      it { expect(ProjectResultsRepository.instance.hours_per_demand_in_time_for_projects([first_project, second_project])).to eq(Time.iso8601('2018-02-16T23:01:46').localtime(0).change(hour: 0).beginning_of_week => 2.066666666666667) }
    end
    context 'when there is no data' do
      let!(:project) { Fabricate :project, customer: customer, product: product, start_date: 1.month.ago, end_date: 1.month.from_now }

      it { expect(ProjectResultsRepository.instance.hours_per_demand_in_time_for_projects([project])).to eq({}) }
    end
  end

  pending '#delivered_until_week'

  describe '#average_demand_cost_in_week_for_projects' do
    let(:team) { Fabricate :team }
    let!(:team_member) { Fabricate :team_member, team: team, monthly_payment: 100 }
    let!(:other_team_member) { Fabricate :team_member, team: team, monthly_payment: 100 }

    context 'when there is data in the week' do
      let!(:first_result) { Fabricate :project_result, project: first_project, result_date: Time.iso8601('2018-02-16T23:01:46'), throughput: 20, qty_hours_downstream: 20, qty_hours_upstream: 11, cost_in_month: 100 }
      let!(:second_result) { Fabricate :project_result, project: second_project, result_date: Time.iso8601('2018-02-16T23:01:46'), throughput: 10, qty_hours_downstream: 20, qty_hours_upstream: 11, cost_in_month: 150 }
      let!(:third_result) { Fabricate :project_result, project: third_project, result_date: Time.iso8601('2018-02-11T23:01:46'), throughput: 5, qty_hours_downstream: 20, qty_hours_upstream: 11, cost_in_month: 50 }
      let!(:out_result) { Fabricate :project_result, result_date: Time.iso8601('2018-02-14T23:01:46'), flow_pressure: 4, cost_in_month: 300 }

      it { expect(ProjectResultsRepository.instance.average_demand_cost_in_week_for_projects([first_project, second_project])).to eq(Time.iso8601('2018-02-16T23:01:46').localtime(0).change(hour: 0).beginning_of_week => 1.0416666666666667) }
    end
    context 'when there is no data' do
      let!(:project) { Fabricate :project, customer: customer, product: product, start_date: 1.month.ago, end_date: 1.month.from_now }

      it { expect(ProjectResultsRepository.instance.average_demand_cost_in_week_for_projects([project])).to eq({}) }
    end
  end

  describe '#create_empty_project_result' do
    let(:company) { Fabricate :company }
    let(:team) { Fabricate :team, company: company }
    let(:customer) { Fabricate :customer, company: company }
    let(:project) { Fabricate :project, customer: customer }
    let(:demand) { Fabricate :demand, project: project }

    context 'when there is no project result to the date' do
      before { ProjectResultsRepository.instance.create_empty_project_result(demand, team, Time.iso8601('2018-02-15T23:01:46')) }
      it { expect(ProjectResult.count).to eq 1 }
    end
    context 'when there is project result to the date' do
      let!(:project_result) { Fabricate :project_result, project: project, result_date: Time.iso8601('2018-02-15T23:01:46') }
      before { ProjectResultsRepository.instance.create_empty_project_result(demand, team, Time.iso8601('2018-02-15T23:01:46')) }
      it { expect(ProjectResult.count).to eq 1 }
    end
    context 'when there is project result to other date' do
      let!(:project_result) { Fabricate :project_result, project: project, result_date: Time.iso8601('2018-02-14T23:01:46').to_date }
      before { ProjectResultsRepository.instance.create_empty_project_result(demand, team, Time.iso8601('2018-02-15T23:01:46')) }
      it { expect(ProjectResult.count).to eq 2 }
    end
  end
end
