# frozen_string_literal: true

RSpec.describe DemandsRepository, type: :repository do
  before { travel_to Time.zone.local(2018, 4, 5, 10, 0, 0) }
  after { travel_back }

  let(:company) { Fabricate :company }
  let(:customer) { Fabricate :customer, company: company }

  describe '#demands_for_company_and_week' do
    let(:first_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }
    let(:second_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }
    let(:third_project) { Fabricate :project, customer: customer, end_date: 1.week.from_now }
    let(:fourth_project) { Fabricate :project, customer: customer, end_date: 1.week.from_now }

    let(:first_project_result) { Fabricate :project_result, project: first_project, result_date: 1.week.ago }
    let(:second_project_result) { Fabricate :project_result, project: second_project, result_date: 1.week.ago }
    let(:third_project_result) { Fabricate :project_result, project: third_project, result_date: Time.zone.today }

    let!(:first_demand) { Fabricate :demand, project_result: first_project_result, demand_id: 'zzz' }
    let!(:second_demand) { Fabricate :demand, project_result: first_project_result, demand_id: 'aaa' }
    let!(:third_demand) { Fabricate :demand, project_result: second_project_result, demand_id: 'sss' }
    let!(:fourth_demand) { Fabricate :demand, project_result: third_project_result }
    let!(:fifth_demand) { Fabricate :demand, project_result: second_project_result, demand_id: 'sss', discarded_at: Time.zone.today }

    it { expect(DemandsRepository.instance.demands_for_company_and_week(company, 1.week.ago.to_date)).to eq [second_demand, third_demand, first_demand] }
  end

  describe '#known_scope_to_date' do
    let(:first_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }
    let(:second_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }

    let!(:first_demand) { Fabricate :demand, project: first_project, created_date: 3.days.ago, discarded_at: nil }
    let!(:second_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: nil }
    let!(:third_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: nil }
    let!(:fourth_demand) { Fabricate :demand, project: first_project, created_date: 1.day.ago, discarded_at: nil }

    let!(:fifth_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: 3.days.ago }
    let!(:sixth_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: 2.days.ago }
    let!(:seventh_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, discarded_at: 1.day.ago }

    let!(:eigth_demand) { Fabricate :demand, project: second_project, created_date: 2.days.ago, discarded_at: nil }

    it { expect(DemandsRepository.instance.known_scope_to_date(first_project, 2.days.ago.to_date)).to eq 5 }
  end

  describe '#demands_finished_per_projects' do
    let(:first_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }
    let(:second_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }

    let!(:first_demand) { Fabricate :demand, project: first_project, created_date: 3.days.ago, end_date: 3.days.ago }
    let!(:second_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, end_date: 2.days.ago }
    let!(:third_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, end_date: 2.days.ago }
    let!(:fourth_demand) { Fabricate :demand, project: second_project, created_date: 1.day.ago, end_date: 1.day.ago }
    let!(:fifth_demand) { Fabricate :demand, project: second_project, created_date: 2.days.ago, end_date: 2.days.ago }

    let!(:sixth_demand) { Fabricate :demand, project: first_project, demand_id: 'sss', discarded_at: Time.zone.today }

    it { expect(DemandsRepository.instance.demands_finished_per_projects([first_project])).to match_array [first_demand, second_demand, third_demand] }
  end

  describe '#demands_per_projects' do
    let(:first_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }
    let(:second_project) { Fabricate :project, customer: customer, start_date: 1.week.ago }

    let!(:first_demand) { Fabricate :demand, project: first_project, created_date: 3.days.ago, end_date: 3.days.ago }
    let!(:second_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago, end_date: 2.days.ago }
    let!(:third_demand) { Fabricate :demand, project: first_project, created_date: 2.days.ago }
    let!(:fourth_demand) { Fabricate :demand, project: second_project, created_date: 1.day.ago, end_date: 1.day.ago }
    let!(:fifth_demand) { Fabricate :demand, project: second_project, created_date: 2.days.ago, end_date: 2.days.ago }

    let!(:sixth_demand) { Fabricate :demand, project: first_project, demand_id: 'sss', discarded_at: Time.zone.today }

    it { expect(DemandsRepository.instance.demands_per_projects([first_project])).to match_array [first_demand, second_demand, third_demand] }
  end

  pending '#full_demand_destroy!'

  describe '#total_queue_time_for' do
    let(:project) { Fabricate :project, customer: customer }

    let(:first_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: true }
    let(:second_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :upstream, queue: true }
    let(:third_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: true, end_point: true }
    let(:fourth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: false }
    let(:fifth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: true }
    let(:sixth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: true }

    let(:demand) { Fabricate :demand, project: project }

    let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-03-02T17:09:58-03:00' }
    let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: demand, last_time_in: '2018-02-02T17:09:58-03:00', last_time_out: '2018-02-10T17:09:58-03:00' }
    let!(:third_transition) { Fabricate :demand_transition, stage: third_stage, demand: demand, last_time_in: '2018-04-02T17:09:58-03:00', last_time_out: '2018-04-20T17:09:58-03:00' }
    let!(:fourth_transition) { Fabricate :demand_transition, stage: fourth_stage, demand: demand, last_time_in: '2018-01-08T17:09:58-03:00', last_time_out: '2018-02-02T17:09:58-03:00' }
    let!(:fifth_transition) { Fabricate :demand_transition, stage: fifth_stage, demand: demand, last_time_in: '2018-03-08T17:09:58-03:00', last_time_out: '2018-04-02T17:09:58-03:00' }
    let!(:sixth_transition) { Fabricate :demand_transition, stage: fifth_stage, demand: demand, last_time_in: '2018-03-08T17:09:58-03:00', last_time_out: '2018-04-02T17:09:58-03:00', discarded_at: Time.zone.today }
    let!(:seventh_transition) { Fabricate :demand_transition, stage: sixth_stage, demand: demand, last_time_in: '2018-04-03T17:09:58-03:00', last_time_out: '2018-05-04T17:09:58-03:00' }

    it { expect(DemandsRepository.instance.total_queue_time_for(demand)).to eq 1416.0 }
  end

  describe '#total_touch_time_for' do
    let(:project) { Fabricate :project, customer: customer }

    let(:first_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: false }
    let(:second_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :upstream, queue: false }
    let(:third_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: false, end_point: true }
    let(:fourth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: true }
    let(:fifth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, queue: false }
    let(:sixth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :upstream, queue: false }

    let(:demand) { Fabricate :demand, project: project }

    let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-03-02T17:09:58-03:00' }
    let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: demand, last_time_in: '2018-02-02T17:09:58-03:00', last_time_out: '2018-02-10T17:09:58-03:00' }
    let!(:third_transition) { Fabricate :demand_transition, stage: third_stage, demand: demand, last_time_in: '2018-04-02T17:09:58-03:00', last_time_out: '2018-04-20T17:09:58-03:00' }
    let!(:fourth_transition) { Fabricate :demand_transition, stage: fourth_stage, demand: demand, last_time_in: '2018-01-08T17:09:58-03:00', last_time_out: '2018-02-02T17:09:58-03:00' }
    let!(:fifth_transition) { Fabricate :demand_transition, stage: fifth_stage, demand: demand, last_time_in: '2018-03-08T17:09:58-03:00', last_time_out: '2018-04-02T17:09:58-03:00' }
    let!(:sixth_transition) { Fabricate :demand_transition, stage: fifth_stage, demand: demand, last_time_in: '2018-04-03T17:09:58-03:00', last_time_out: '2018-05-04T17:09:58-03:00', discarded_at: Time.zone.today }
    let!(:seventh_transition) { Fabricate :demand_transition, stage: sixth_stage, demand: demand, last_time_in: '2018-04-03T17:09:58-03:00', last_time_out: '2018-05-04T17:09:58-03:00' }

    it { expect(DemandsRepository.instance.total_touch_time_for(demand)).to eq 672.0 }
  end

  describe '#committed_demands_by_project_and_week' do
    let(:first_project) { Fabricate :project, start_date: 3.weeks.ago }
    let(:second_project) { Fabricate :project, start_date: 3.weeks.ago }

    context 'having data' do
      let!(:first_demand) { Fabricate :demand, project: first_project, commitment_date: 3.weeks.ago }
      let!(:second_demand) { Fabricate :demand, project: first_project, commitment_date: 2.weeks.ago }
      let!(:third_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago }
      let!(:fifth_demand) { Fabricate :demand, project: second_project, commitment_date: 1.week.ago }
      let!(:sixth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago, discarded_at: Time.zone.today }

      it { expect(DemandsRepository.instance.committed_demands_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)).to match_array [third_demand, fourth_demand, fifth_demand] }
    end
    context 'having no data' do
      it { expect(DemandsRepository.instance.committed_demands_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)).to eq [] }
    end
  end

  describe '#throughput_by_project_and_week' do
    let(:first_project) { Fabricate :project, start_date: 3.weeks.ago }
    let(:second_project) { Fabricate :project, start_date: 3.weeks.ago }

    context 'having data' do
      let!(:first_demand) { Fabricate :demand, project: first_project, end_date: 3.weeks.ago }
      let!(:second_demand) { Fabricate :demand, project: first_project, end_date: 2.weeks.ago }
      let!(:third_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago }
      let!(:fifth_demand) { Fabricate :demand, project: second_project, end_date: 1.week.ago }
      let!(:sixth_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago, discarded_at: Time.zone.today }

      it { expect(DemandsRepository.instance.throughput_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)).to match_array [third_demand, fourth_demand, fifth_demand] }
    end
    context 'having no data' do
      it { expect(DemandsRepository.instance.throughput_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)).to eq [] }
    end
  end

  describe '#working_in_progress_for' do
    let(:project) { Fabricate :project }

    context 'having demands' do
      let!(:first_demand) { Fabricate :demand, project: project, commitment_date: Time.zone.yesterday, end_date: nil }
      let!(:second_demand) { Fabricate :demand, project: project, commitment_date: 2.days.ago, end_date: Time.zone.tomorrow }
      let!(:third_demand) { Fabricate :demand, project: project, commitment_date: 3.days.ago, end_date: Time.zone.local(2018, 4, 5, 20, 59, 59) }
      let!(:fourth_demand) { Fabricate :demand, project: project, commitment_date: Time.zone.yesterday, end_date: Time.zone.yesterday }
      let!(:fifth_demand) { Fabricate :demand, project: project, commitment_date: Time.zone.tomorrow, end_date: Time.zone.tomorrow }
      let!(:sixth_demand) { Fabricate :demand, project: project, commitment_date: Time.zone.now, end_date: Time.zone.tomorrow }
      let!(:seventh_demand) { Fabricate :demand, project: project, commitment_date: Time.zone.yesterday, end_date: nil, discarded_at: Time.zone.today }

      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.work_in_progress_for([project], Time.zone.today)).to eq [third_demand, second_demand, first_demand, sixth_demand] }
      end
    end

    context 'having no demands' do
      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.work_in_progress_for([project], Time.zone.today)).to eq [] }
      end
    end
  end

  describe '#grouped_by_effort_upstream_per_month' do
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

      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.grouped_by_effort_upstream_per_month([project], 57.days.ago.to_date)).to eq([2018.0, 2.0] => 22.0, [2018.0, 3.0] => 195.0) }
        it { expect(DemandsRepository.instance.grouped_by_effort_upstream_per_month([project], 24.days.ago.to_date)).to eq([2018.0, 3.0] => 195.0) }
      end
    end

    context 'having no demands' do
      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.grouped_by_effort_upstream_per_month([project], Time.zone.today)).to eq({}) }
      end
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

      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.grouped_by_effort_downstream_per_month([project], 57.days.ago.to_date)).to eq([2018.0, 2.0] => 25.0, [2018.0, 3.0] => 186.0) }
        it { expect(DemandsRepository.instance.grouped_by_effort_downstream_per_month([project], 24.days.ago.to_date)).to eq([2018.0, 3.0] => 186.0) }
      end
    end

    context 'having no demands' do
      context 'having demands in progress' do
        it { expect(DemandsRepository.instance.grouped_by_effort_downstream_per_month([project], Time.zone.today)).to eq({}) }
      end
    end
  end

  describe '#not_started_demands' do
    let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:second_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:third_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let(:first_stage) { Fabricate :stage, company: company, projects: [first_project], integration_pipe_id: '123', order: 0 }
      let(:second_stage) { Fabricate :stage, company: company, projects: [first_project], integration_pipe_id: '123', order: 1 }
      let(:third_stage) { Fabricate :stage, company: company, projects: [second_project], integration_pipe_id: '543', order: 0 }
      let(:fourth_stage) { Fabricate :stage, company: company, projects: [third_project], integration_pipe_id: '543', order: 0 }

      let!(:first_demand) { Fabricate :demand, project: first_project }
      let!(:second_demand) { Fabricate :demand, project: first_project }
      let!(:third_demand) { Fabricate :demand, project: first_project }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, commitment_date: nil }
      let!(:fifth_demand) { Fabricate :demand, project: first_project, commitment_date: Time.zone.today }
      let!(:sixth_demand) { Fabricate :demand, project: second_project }
      let!(:seventh_demand) { Fabricate :demand, project: third_project }
      let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: nil, discarded_at: Time.zone.today }

      let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: first_demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-02-28T17:09:58-03:00' }
      let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: first_demand, last_time_in: '2018-02-28T17:09:58-03:00' }
      let!(:third_transition) { Fabricate :demand_transition, stage: first_stage, demand: second_demand, last_time_in: '2018-04-03T17:09:58-03:00', last_time_out: '2018-04-03T17:09:58-03:00' }
      let!(:fourth_transition) { Fabricate :demand_transition, stage: second_stage, demand: second_demand, last_time_in: '2018-04-03T17:09:58-03:00', last_time_out: '2018-04-04T17:09:58-03:00' }
      let!(:fifth_transition) { Fabricate :demand_transition, stage: first_stage, demand: second_demand, last_time_in: '2018-04-04T17:09:58-03:00' }
      let!(:sixth_transition) { Fabricate :demand_transition, stage: first_stage, demand: third_demand, last_time_in: '2018-04-04T17:09:58-03:00' }
      let!(:seventh_transition) { Fabricate :demand_transition, stage: third_stage, demand: sixth_demand, last_time_in: '2018-04-04T17:09:58-03:00' }
      let!(:eigth_transition) { Fabricate :demand_transition, stage: fourth_stage, demand: seventh_demand, last_time_in: '2018-04-04T17:09:58-03:00' }

      it { expect(DemandsRepository.instance.not_started_demands([first_project, second_project])).to match_array [second_demand, third_demand, fourth_demand, sixth_demand] }
    end

    context 'having no demands' do
      context 'having no demands' do
        it { expect(DemandsRepository.instance.not_started_demands([first_project])).to eq [] }
      end
    end
  end

  describe '#committed_demands' do
    let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:second_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }
    let(:third_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

    context 'having demands' do
      let(:first_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], integration_pipe_id: '123', order: 0 }
      let(:second_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], integration_pipe_id: '123', order: 1, commitment_point: true }
      let(:third_stage) { Fabricate :stage, company: company, projects: [first_project, second_project], integration_pipe_id: '123', order: 2 }
      let(:fourth_stage) { Fabricate :stage, company: company, projects: [third_project], integration_pipe_id: '543', order: 0 }

      let!(:first_demand) { Fabricate :demand, project: first_project }
      let!(:second_demand) { Fabricate :demand, project: first_project }
      let!(:third_demand) { Fabricate :demand, project: first_project }
      let!(:fourth_demand) { Fabricate :demand, project: first_project, commitment_date: nil }
      let!(:fifth_demand) { Fabricate :demand, project: first_project, commitment_date: Time.zone.today }
      let!(:sixth_demand) { Fabricate :demand, project: second_project }
      let!(:seventh_demand) { Fabricate :demand, project: third_project, commitment_date: Time.zone.today, end_date: Time.zone.tomorrow }

      let!(:eigth_demand) { Fabricate :demand, project: second_project, commitment_date: Time.zone.today, discarded_at: Time.zone.today }

      let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: first_demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-02-28T17:09:58-03:00' }
      let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: second_demand, last_time_in: '2018-02-28T17:09:58-03:00' }
      let!(:third_transition) { Fabricate :demand_transition, stage: first_stage, demand: second_demand, last_time_in: '2018-04-03T17:09:58-03:00', last_time_out: '2018-04-03T17:09:58-03:00' }
      let!(:fourth_transition) { Fabricate :demand_transition, stage: second_stage, demand: second_demand, last_time_in: '2018-04-03T17:09:58-03:00', last_time_out: '2018-04-04T17:09:58-03:00' }
      let!(:fifth_transition) { Fabricate :demand_transition, stage: third_stage, demand: second_demand, last_time_in: '2018-04-04T17:09:58-03:00' }
      let!(:sixth_transition) { Fabricate :demand_transition, stage: first_stage, demand: third_demand, last_time_in: '2018-04-04T17:09:58-03:00' }
      let!(:seventh_transition) { Fabricate :demand_transition, stage: second_stage, demand: third_demand, last_time_in: '2018-04-04T17:09:58-03:00' }
      let!(:eigth_transition) { Fabricate :demand_transition, stage: third_stage, demand: sixth_demand, last_time_in: '2018-04-04T17:09:58-03:00' }
      let!(:nineth_transition) { Fabricate :demand_transition, stage: fourth_stage, demand: seventh_demand, last_time_in: '2018-04-04T17:09:58-03:00' }

      it { expect(DemandsRepository.instance.committed_demands([first_project, second_project])).to match_array [first_demand, second_demand, third_demand, fifth_demand, sixth_demand] }
    end

    context 'having no demands' do
      context 'having no demands' do
        it { expect(DemandsRepository.instance.committed_demands([first_project])).to eq [] }
      end
    end
  end
end
