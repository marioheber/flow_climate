# frozen_string_literal: true

RSpec.describe DemandsRepository, type: :repository do
  before { travel_to Time.zone.local(2018, 4, 5, 10, 0, 0) }
  after { travel_back }

  let(:company) { Fabricate :company }
  let(:customer) { Fabricate :customer, company: company }
  let(:other_customer) { Fabricate :customer }

  let(:first_project) { Fabricate :project, customer: customer, start_date: 4.weeks.ago }
  let(:second_project) { Fabricate :project, customer: customer, start_date: 3.weeks.ago }
  let(:third_project) { Fabricate :project, customer: other_customer, end_date: 1.week.from_now }
  let(:fourth_project) { Fabricate :project, customer: customer, end_date: 1.week.from_now }

  describe '#known_scope_to_date' do
    let!(:first_demand) { Fabricate :demand, project: first_project, created_date: 3.days.ago, discarded_at: nil }
    let!(:second_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: nil }
    let!(:third_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: nil }
    let!(:fourth_demand) { Fabricate :demand, project: first_project, created_date: 1.day.ago, discarded_at: nil }

    let!(:fifth_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: 3.days.ago }
    let!(:sixth_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: 2.days.ago }
    let!(:seventh_demand) { Fabricate :demand, project: first_project, created_date: 3.days.ago, discarded_at: Time.zone.now }

    let!(:eigth_demand) { Fabricate :demand, project: second_project, created_date: 4.days.ago, discarded_at: nil }
    let!(:nineth_demand) { Fabricate :demand, project: third_project, created_date: 4.days.ago, discarded_at: nil }

    let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

    it { expect(DemandsRepository.instance.known_scope_to_date([first_project, second_project], 2.days.ago)).to eq 65 }
  end

  describe '#demands_to_projects' do
    let!(:first_demand) { Fabricate :demand, project: first_project, demand_id: 'first_demand', created_date: 4.days.ago, end_date: 3.days.ago, discarded_at: nil }
    let!(:second_demand) { Fabricate :demand, project: first_project, demand_id: 'second_demand', created_date: 3.days.ago, end_date: 2.days.ago, discarded_at: nil }
    let!(:third_demand) { Fabricate :demand, project: first_project, demand_id: 'third_demand', created_date: 2.days.ago, end_date: nil, discarded_at: nil }
    let!(:fourth_demand) { Fabricate :demand, project: second_project, demand_id: 'fourth_demand', created_date: 1.day.ago, end_date: 1.day.ago, discarded_at: nil }
    let!(:fifth_demand) { Fabricate :demand, project: second_project, demand_id: 'fifth_demand', created_date: 2.days.ago, end_date: 2.days.ago, discarded_at: nil }

    let!(:sixth_demand) { Fabricate :demand, project: first_project, demand_id: 'sixth_demand', discarded_at: Time.zone.today }

    let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

    subject(:query_return) { DemandsRepository.instance.demands_to_projects([first_project]) }

    it { expect(query_return.map(&:id)).to match_array [first_demand.id, second_demand.id, third_demand.id] }
  end

  describe '#committed_demands_by_project_and_week' do
    context 'having data' do
      let!(:first_demand) { Fabricate :demand, project: first_project, commitment_date: 3.weeks.ago }
      let!(:second_demand) { Fabricate :demand, project: first_project, commitment_date: 2.weeks.ago }
      let!(:third_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago }
      let!(:fifth_demand) { Fabricate :demand, project: second_project, commitment_date: 1.week.ago }
      let!(:sixth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago, discarded_at: Time.zone.today }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      it { expect(DemandsRepository.instance.committed_demands_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)).to match_array [third_demand, fourth_demand, fifth_demand] }
    end
    context 'having no data' do
      it { expect(DemandsRepository.instance.committed_demands_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)).to eq [] }
    end
  end

  describe '#throughput_to_projects_and_period' do
    context 'having data' do
      let!(:first_demand) { Fabricate :demand, project: first_project, end_date: 3.weeks.ago }
      let!(:second_demand) { Fabricate :demand, project: first_project, end_date: 2.weeks.ago }
      let!(:third_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago }
      let!(:fifth_demand) { Fabricate :demand, project: second_project, end_date: 1.week.ago }
      let!(:sixth_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago, discarded_at: Time.zone.today }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      it { expect(DemandsRepository.instance.throughput_to_projects_and_period(Project.all, 1.week.ago.beginning_of_week, 1.week.ago.end_of_week)).to match_array [third_demand, fourth_demand, fifth_demand] }
    end
    context 'having no data' do
      it { expect(DemandsRepository.instance.throughput_to_projects_and_period(Project.all, 1.week.ago.beginning_of_week, 1.week.ago.end_of_week)).to eq [] }
    end
  end

  describe '#effort_upstream_grouped_by_month' do
    let(:project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let!(:first_demand) { Fabricate :demand, project: project, commitment_date: 60.days.ago, end_date: 57.days.ago, effort_upstream: 10, effort_downstream: 5 }
      let!(:second_demand) { Fabricate :demand, project: project, commitment_date: 58.days.ago, end_date: 55.days.ago, effort_upstream: 12, effort_downstream: 20 }
      let!(:third_demand) { Fabricate :demand, project: project, commitment_date: 30.days.ago, end_date: 24.days.ago, effort_upstream: 27, effort_downstream: 40 }
      let!(:fourth_demand) { Fabricate :demand, project: project, commitment_date: 29.days.ago, end_date: 22.days.ago, effort_upstream: 80, effort_downstream: 34 }
      let!(:fifth_demand) { Fabricate :demand, project: project, commitment_date: 10.days.ago, end_date: 7.days.ago, effort_upstream: 56, effort_downstream: 25 }
      let!(:sixth_demand) { Fabricate :demand, project: project, commitment_date: 10.days.ago, end_date: 5.days.ago, effort_upstream: 32, effort_downstream: 87 }
      let!(:seventh_demand) { Fabricate :demand, project: project, commitment_date: 10.days.ago, end_date: nil, effort_upstream: 32, effort_downstream: 87 }
      let!(:eigth_demand) { Fabricate :demand, project: project, commitment_date: 29.days.ago, end_date: 22.days.ago, effort_upstream: 80, effort_downstream: 34, discarded_at: Time.zone.today }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      context 'having demands' do
        it { expect(DemandsRepository.instance.effort_upstream_grouped_by_month(Project.all, 57.days.ago.to_date)).to eq([2018.0, 2.0] => 22.0, [2018.0, 3.0] => 195.0) }
        it { expect(DemandsRepository.instance.effort_upstream_grouped_by_month(Project.all, 24.days.ago.to_date)).to eq([2018.0, 3.0] => 195.0) }
      end
    end

    context 'having no demands' do
      it { expect(DemandsRepository.instance.effort_upstream_grouped_by_month(Project.all, Time.zone.today)).to eq({}) }
    end
  end

  describe '#grouped_by_effort_downstream_per_month' do
    let(:project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let!(:first_demand) { Fabricate :demand, project: project, commitment_date: 60.days.ago, end_date: 57.days.ago, effort_upstream: 10, effort_downstream: 5 }
      let!(:second_demand) { Fabricate :demand, project: project, commitment_date: 58.days.ago, end_date: 55.days.ago, effort_upstream: 12, effort_downstream: 20 }
      let!(:third_demand) { Fabricate :demand, project: project, commitment_date: 30.days.ago, end_date: 24.days.ago, effort_upstream: 27, effort_downstream: 40 }
      let!(:fourth_demand) { Fabricate :demand, project: project, commitment_date: 29.days.ago, end_date: 22.days.ago, effort_upstream: 80, effort_downstream: 34 }
      let!(:fifth_demand) { Fabricate :demand, project: project, commitment_date: 10.days.ago, end_date: 7.days.ago, effort_upstream: 56, effort_downstream: 25 }
      let!(:sixth_demand) { Fabricate :demand, project: project, commitment_date: 10.days.ago, end_date: 5.days.ago, effort_upstream: 32, effort_downstream: 87 }
      let!(:seventh_demand) { Fabricate :demand, project: project, commitment_date: 10.days.ago, end_date: nil, effort_upstream: 32, effort_downstream: 87 }
      let!(:eigth_demand) { Fabricate :demand, project: project, commitment_date: 29.days.ago, end_date: 22.days.ago, effort_upstream: 80, effort_downstream: 34, discarded_at: Time.zone.today }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.grouped_by_effort_downstream_per_month(Project.all, 57.days.ago.to_date)).to eq([2018.0, 2.0] => 25.0, [2018.0, 3.0] => 186.0) }
        it { expect(DemandsRepository.instance.grouped_by_effort_downstream_per_month(Project.all, 24.days.ago.to_date)).to eq([2018.0, 3.0] => 186.0) }
      end
    end

    context 'having no demands' do
      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.grouped_by_effort_downstream_per_month(Project.all, Time.zone.today)).to eq({}) }
      end
    end
  end

  describe '#delivered_until_date_to_projects_in_upstream' do
    let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:second_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:third_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      context 'upstream' do
        let(:first_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], integration_pipe_id: '123', order: 0, stage_stream: :upstream }
        let(:second_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], integration_pipe_id: '123', order: 1, stage_stream: :upstream, end_point: true }

        let!(:first_demand) { Fabricate :demand, project: first_project, downstream: false }
        let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false }
        let!(:third_demand) { Fabricate :demand, project: first_project, downstream: false }

        let!(:fourth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today }

        let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

        let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: first_demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-02-28T17:09:58-03:00' }
        let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: second_demand, last_time_in: '2018-02-28T17:09:58-03:00', last_time_out: nil }
        let!(:third_transition) { Fabricate :demand_transition, stage: second_stage, demand: third_demand, last_time_in: '2018-04-04T17:09:58-03:00', last_time_out: nil }

        it { expect(DemandsRepository.instance.delivered_until_date_to_projects_in_stream(Project.all, 'upstream')).to match_array [second_demand, third_demand] }
        it { expect(DemandsRepository.instance.delivered_until_date_to_projects_in_stream(Project.all, 'upstream', Date.new(2018, 3, 1))).to eq [second_demand] }
      end
      context 'downstream' do
        let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
        let(:second_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
        let(:third_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

        context 'having demands' do
          let(:first_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], integration_pipe_id: '123', order: 0, stage_stream: :downstream }
          let(:second_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], integration_pipe_id: '123', order: 1, stage_stream: :downstream, end_point: true }

          let!(:first_demand) { Fabricate :demand, project: first_project, downstream: false }
          let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false }
          let!(:third_demand) { Fabricate :demand, project: first_project, downstream: false }
          let!(:fourth_demand) { Fabricate :demand, project: first_project, downstream: false, commitment_date: nil }
          let!(:fifth_demand) { Fabricate :demand, project: first_project, downstream: false, commitment_date: Time.zone.today }
          let!(:sixth_demand) { Fabricate :demand, project: second_project, downstream: false }
          let!(:seventh_demand) { Fabricate :demand, project: third_project, downstream: false, commitment_date: Time.zone.today, end_date: Time.zone.tomorrow }

          let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today }

          let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

          let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: first_demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-02-28T17:09:58-03:00' }
          let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: second_demand, last_time_in: '2018-02-28T17:09:58-03:00', last_time_out: nil }
          let!(:seventh_transition) { Fabricate :demand_transition, stage: second_stage, demand: third_demand, last_time_in: '2018-04-04T17:09:58-03:00', last_time_out: nil }

          it { expect(DemandsRepository.instance.delivered_until_date_to_projects_in_stream(Project.all, 'downstream')).to match_array [second_demand, third_demand] }
          it { expect(DemandsRepository.instance.delivered_until_date_to_projects_in_stream(Project.all, 'downstream', Date.new(2018, 3, 1))).to eq [second_demand] }
        end
      end
    end

    context 'having no demands' do
      context 'having no demands' do
        it { expect(DemandsRepository.instance.delivered_until_date_to_projects_in_stream(Project.all, 'upstream')).to eq [] }
      end
    end
  end

  describe '#delivered_hours_in_month_for_projects' do
    let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:second_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:third_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let!(:first_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 4.days.ago, effort_upstream: 558, effort_downstream: 929 }
      let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.day.ago, effort_upstream: 932, effort_downstream: 112 }
      let!(:third_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: 3.weeks.ago, effort_upstream: 536, effort_downstream: 643 }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: nil, effort_upstream: 210, effort_downstream: 432 }
      let!(:fifth_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.week.ago, effort_upstream: 1100, effort_downstream: 230 }
      let!(:sixth_demand) { Fabricate :demand, project: second_project, downstream: false, end_date: 1.month.ago, effort_upstream: 100, effort_downstream: 23 }
      let!(:seventh_demand) { Fabricate :demand, project: third_project, downstream: true, commitment_date: Time.zone.today, end_date: Time.zone.tomorrow, effort_upstream: 120, effort_downstream: 723 }

      let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today, effort_upstream: 54_321, effort_downstream: 15_223 }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      it { expect(DemandsRepository.instance.delivered_hours_in_month_for_projects(Project.all).to_f).to eq 3374.0 }
      it { expect(DemandsRepository.instance.delivered_hours_in_month_for_projects(Project.all, Date.new(2018, 3, 1)).to_f).to eq 2632.0 }
    end

    context 'having no demands' do
      context 'having no demands' do
        it { expect(DemandsRepository.instance.delivered_hours_in_month_for_projects(Project.all)).to eq 0 }
      end
    end
  end

  describe '#count_grouped_per_period' do
    let!(:first_demand) { Fabricate :demand, project: first_project, downstream: false, commitment_date: 6.days.ago, end_date: 4.days.ago, effort_upstream: 558, effort_downstream: 929 }
    let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false, commitment_date: 4.days.ago, end_date: 1.day.ago, effort_upstream: 932, effort_downstream: 112 }
    let!(:third_demand) { Fabricate :demand, project: first_project, downstream: true, commitment_date: 6.weeks.ago, end_date: 3.weeks.ago, effort_upstream: 536, effort_downstream: 643 }
    let!(:fourth_demand) { Fabricate :demand, project: first_project, downstream: true, commitment_date: 6.days.ago, end_date: nil, effort_upstream: 210, effort_downstream: 432 }
    let!(:fifth_demand) { Fabricate :demand, project: first_project, downstream: false, commitment_date: nil, end_date: 1.week.ago, effort_upstream: 1100, effort_downstream: 230 }
    let!(:sixth_demand) { Fabricate :demand, project: second_project, downstream: false, commitment_date: 5.weeks.ago, end_date: 1.month.ago, effort_upstream: 100, effort_downstream: 23 }
    let!(:seventh_demand) { Fabricate :demand, project: third_project, downstream: true, commitment_date: Time.zone.today, end_date: Time.zone.tomorrow, effort_upstream: 120, effort_downstream: 723 }

    let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today, effort_upstream: 54_321, effort_downstream: 15_223 }

    let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

    context 'not specifying the group period' do
      context 'for end_date' do
        subject(:result_data) { DemandsRepository.instance.count_grouped_per_period(Demand.all, :end_date) }
        it 'returns grouped per week using the end date' do
          expect(result_data[Date.new(2018, 3, 5)]).to eq 1
          expect(result_data[Date.new(2018, 3, 12)]).to eq 1
          expect(result_data[Date.new(2018, 3, 26)]).to eq 2
          expect(result_data[Date.new(2018, 4, 2)]).to eq 2
        end
      end
      context 'for created_date' do
        subject(:result_data) { DemandsRepository.instance.count_grouped_per_period(Demand.all, :created_date) }
        it 'returns grouped per week to created date' do
          expect(result_data[Date.new(2018, 3, 26)]).to eq 7
        end
      end
      context 'for commitment_date' do
        subject(:result_data) { DemandsRepository.instance.count_grouped_per_period(Demand.all, :commitment_date) }
        it 'returns grouped per week to commitment date' do
          expect(result_data[Date.new(2018, 3, 26)]).to eq 3
        end
      end
    end

    context 'specifying the week period' do
      subject(:result_data) { DemandsRepository.instance.count_grouped_per_period(Demand.all, :end_date, 'week') }
      it 'returns grouped per week' do
        expect(result_data[Date.new(2018, 3, 5)]).to eq 1
        expect(result_data[Date.new(2018, 3, 12)]).to eq 1
        expect(result_data[Date.new(2018, 3, 26)]).to eq 2
        expect(result_data[Date.new(2018, 4, 2)]).to eq 2
      end
    end

    context 'specifying the month period' do
      subject(:result_data) { DemandsRepository.instance.count_grouped_per_period(Demand.all, :end_date, 'month') }
      it 'returns grouped per month' do
        expect(result_data[Date.new(2018, 3, 1)]).to eq 3
        expect(result_data[Date.new(2018, 4, 1)]).to eq 3
      end
    end

    context 'specifying the day period' do
      subject(:result_data) { DemandsRepository.instance.count_grouped_per_period(Demand.all, :end_date, 'day') }
      it 'returns grouped per day' do
        expect(result_data[Date.new(2018, 3, 5)]).to eq 1
        expect(result_data[Date.new(2018, 3, 15)]).to eq 1
        expect(result_data[Date.new(2018, 3, 29)]).to eq 1
        expect(result_data[Date.new(2018, 4, 1)]).to eq 1
        expect(result_data[Date.new(2018, 4, 4)]).to eq 1
        expect(result_data[Date.new(2018, 4, 6)]).to eq 1
      end
    end

    context 'specifying the year period' do
      subject(:result_data) { DemandsRepository.instance.count_grouped_per_period(Demand.all, :end_date, 'year') }
      it 'returns grouped per year' do
        expect(result_data[Date.new(2018, 1, 1)]).to eq 6
      end
    end
  end

  describe '#demands_for_period' do
    let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:second_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:third_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let!(:first_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 4.days.ago, effort_upstream: 558, effort_downstream: 929 }
      let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.day.ago, effort_upstream: 932, effort_downstream: 112 }
      let!(:third_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: 3.weeks.ago, effort_upstream: 536, effort_downstream: 643 }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: nil, effort_upstream: 210, effort_downstream: 432 }
      let!(:fifth_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.week.ago, effort_upstream: 1100, effort_downstream: 230 }
      let!(:sixth_demand) { Fabricate :demand, project: second_project, downstream: false, end_date: 1.month.ago, effort_upstream: 100, effort_downstream: 23 }
      let!(:seventh_demand) { Fabricate :demand, project: third_project, downstream: true, commitment_date: Time.zone.today, end_date: Time.zone.tomorrow, effort_upstream: 120, effort_downstream: 723 }

      let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today, effort_upstream: 54_321, effort_downstream: 15_223 }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      it { expect(DemandsRepository.instance.demands_for_period(Demand.all, 4.days.ago, Time.zone.now)).to match_array [first_demand, second_demand] }
    end

    context 'having no demands' do
      context 'having no demands' do
        it { expect(DemandsRepository.instance.demands_for_period(Demand.all, 4.days.ago, Time.zone.now)).to eq [] }
      end
    end
  end

  describe '#demands_for_period_accumulated' do
    let(:first_project) { Fabricate :project, customer: customer, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:second_project) { Fabricate :project, customer: customer, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:third_project) { Fabricate :project, customer: customer, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let!(:first_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 4.days.ago, effort_upstream: 558, effort_downstream: 929 }
      let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.day.ago, effort_upstream: 932, effort_downstream: 112 }
      let!(:third_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: 3.weeks.ago, effort_upstream: 536, effort_downstream: 643 }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: nil, effort_upstream: 210, effort_downstream: 432 }
      let!(:fifth_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.week.ago, effort_upstream: 1100, effort_downstream: 230 }
      let!(:sixth_demand) { Fabricate :demand, project: second_project, downstream: false, end_date: 1.month.ago, effort_upstream: 100, effort_downstream: 23 }
      let!(:seventh_demand) { Fabricate :demand, project: third_project, downstream: true, commitment_date: Time.zone.today, end_date: Time.zone.tomorrow, effort_upstream: 120, effort_downstream: 723 }

      let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today, effort_upstream: 54_321, effort_downstream: 15_223 }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      it { expect(DemandsRepository.instance.demands_for_period_accumulated(Demand.all, 1.week.ago)).to match_array [third_demand, fifth_demand, sixth_demand] }
    end

    context 'having no demands' do
      context 'having no demands' do
        it { expect(DemandsRepository.instance.demands_for_period_accumulated(Demand.all, 4.days.ago)).to eq [] }
      end
    end
  end

  describe '#cumulative_flow_for_week' do
    let(:first_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], name: 'first_stage', integration_pipe_id: '123', order: 0, stage_stream: :downstream }
    let(:second_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], name: 'second_stage', integration_pipe_id: '123', order: 1, stage_stream: :downstream, end_point: true }

    let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:second_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:third_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let!(:first_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 4.days.ago, effort_upstream: 558, effort_downstream: 929 }
      let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.day.ago, effort_upstream: 932, effort_downstream: 112 }
      let!(:third_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: 3.weeks.ago, effort_upstream: 536, effort_downstream: 643 }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, downstream: true, end_date: nil, effort_upstream: 210, effort_downstream: 432 }
      let!(:fifth_demand) { Fabricate :demand, project: first_project, downstream: false, end_date: 1.week.ago, effort_upstream: 1100, effort_downstream: 230 }
      let!(:sixth_demand) { Fabricate :demand, project: second_project, downstream: false, end_date: 1.month.ago, effort_upstream: 100, effort_downstream: 23 }

      let!(:seventh_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today, effort_upstream: 54_321, effort_downstream: 15_223 }
      let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: 2.weeks.ago, effort_upstream: 54_321, effort_downstream: 15_223 }

      let!(:first_epic) { Fabricate :demand, project: first_project, artifact_type: :epic }

      let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: first_demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-02-28T17:09:58-03:00' }
      let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: second_demand, last_time_in: '2018-03-01T17:09:58-03:00', last_time_out: '2018-03-01T17:09:58-03:00' }
      let!(:third_transition) { Fabricate :demand_transition, stage: first_stage, demand: third_demand, last_time_in: '2018-03-04T17:09:58-03:00', last_time_out: nil }
      let!(:fourth_transition) { Fabricate :demand_transition, stage: second_stage, demand: fourth_demand, last_time_in: '2018-03-10T17:09:58-03:00', last_time_out: nil }
      let!(:fifth_transition) { Fabricate :demand_transition, stage: first_stage, demand: fifth_demand, last_time_in: '2018-03-15T17:09:58-03:00', last_time_out: nil }
      let!(:sixth_transition) { Fabricate :demand_transition, stage: first_stage, demand: seventh_demand, last_time_in: '2018-03-01T17:09:58-03:00', last_time_out: nil }
      let!(:seventh_transition) { Fabricate :demand_transition, stage: first_stage, demand: eigth_demand, last_time_in: '2018-04-01T17:09:58-03:00', last_time_out: nil }

      it { expect(DemandsRepository.instance.cumulative_flow_for_week(Demand.all.map(&:id), 1.week.ago, :downstream)).to eq(first_stage.name => 4, second_stage.name => 2) }
    end

    context 'having no demands' do
      context 'having no demands' do
        it { expect(DemandsRepository.instance.cumulative_flow_for_week(Demand.all.map(&:id), 1.week.ago, :downstream)).to eq({}) }
      end
    end
  end

  describe '#total_time_for' do
    let(:company) { Fabricate :company }
    let(:customer) { Fabricate :customer, company: company }
    let(:project) { Fabricate :project, customer: customer }

    let(:first_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: false, order: 1 }
    let(:second_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: false, order: 2 }
    let(:fourth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :upstream, queue: false, order: 3 }

    let(:third_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: true, order: 4 }
    let(:fifth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: true, order: 5, end_point: true }

    let(:demand) { Fabricate :demand, project: project }
    let(:other_demand) { Fabricate :demand, project: project }

    let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-03-02T17:09:58-03:00' }
    let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: demand, last_time_in: '2018-02-02T17:09:58-03:00', last_time_out: '2018-02-09T17:09:58-03:00' }
    let!(:fourth_transition) { Fabricate :demand_transition, stage: fourth_stage, demand: demand, last_time_in: '2018-01-08T17:09:58-03:00', last_time_out: '2018-02-02T17:09:58-03:00' }

    let!(:third_transition) { Fabricate :demand_transition, stage: third_stage, demand: demand, last_time_in: '2018-04-02T17:09:58-03:00', last_time_out: '2018-05-15T17:09:58-03:00' }
    let!(:fifth_transition) { Fabricate :demand_transition, stage: fifth_stage, demand: demand, last_time_in: '2018-03-08T17:09:58-03:00', last_time_out: '2018-04-02T17:09:58-03:00' }

    let!(:sixth_transition) { Fabricate :demand_transition, stage: first_stage, demand: other_demand, last_time_in: '2018-03-17T17:09:58-03:00', last_time_out: '2018-03-18T17:09:58-03:00' }
    let!(:seventh_transition) { Fabricate :demand_transition, stage: second_stage, demand: other_demand, last_time_in: '2018-03-19T17:09:58-03:00', last_time_out: '2018-03-20T17:09:58-03:00' }
    let!(:eigth_transition) { Fabricate :demand_transition, stage: fourth_stage, demand: other_demand, last_time_in: '2018-03-21T17:09:58-03:00', last_time_out: '2018-03-23T17:09:58-03:00' }

    let!(:ninth_transition) { Fabricate :demand_transition, stage: third_stage, demand: other_demand, last_time_in: '2018-03-24T17:09:58-03:00', last_time_out: '2018-03-25T17:09:58-03:00' }
    let!(:tenth_transition) { Fabricate :demand_transition, stage: fifth_stage, demand: other_demand, last_time_in: '2018-03-26T17:09:58-03:00', last_time_out: '2018-03-27T17:09:58-03:00' }

    it { expect(DemandsRepository.instance.total_time_for(Project.all, 'total_queue_time')).to eq([10, 2018] => 3_715_200.0, [13, 2018] => 86_400.0) }
    it { expect(DemandsRepository.instance.total_time_for(Project.all, 'total_touch_time')).to eq([10, 2018] => 3_024_000.0, [13, 2018] => 345_600.0) }
  end

  describe '#demands_delivered_grouped_by_projects_to_period' do
    let(:first_project) { Fabricate :project, start_date: 3.days.ago, end_date: 2.days.from_now }
    let(:second_project) { Fabricate :project, start_date: 2.days.ago, end_date: 1.day.from_now }

    let!(:first_demand) { Fabricate :demand, project: first_project, end_date: 1.day.ago }
    let!(:second_demand) { Fabricate :demand, project: first_project, end_date: Time.zone.today }
    let!(:third_demand) { Fabricate :demand, project: second_project, end_date: 2.days.ago }
    let!(:fourth_demand) { Fabricate :demand, project: first_project, end_date: 1.day.ago }
    let!(:fifth_demand) { Fabricate :demand, project: first_project, end_date: 1.day.ago }

    it { expect(DemandsRepository.instance.demands_delivered_grouped_by_projects_to_period([first_project, second_project], 3.days.ago, 2.days.from_now)[first_project.full_name]).to match_array [first_demand, second_demand, fourth_demand, fifth_demand] }
    it { expect(DemandsRepository.instance.demands_delivered_grouped_by_projects_to_period([first_project, second_project], 3.days.ago, 2.days.from_now)[second_project.full_name]).to match_array [third_demand] }
  end

  pending '#bugs_opened_until_limit_date'
  pending '#bugs_closed_until_limit_date'
end
