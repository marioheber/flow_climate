# frozen_string_literal: true

RSpec.describe DemandTransitionsRepository, type: :repository do
  describe '#summed_transitions_time_grouped_by_stage_demand_for' do
    context 'having data' do
      let(:company) { Fabricate :company }

      let(:first_project) { Fabricate :project, start_date: 2.months.ago, end_date: 2.months.from_now }

      let(:first_stage) { Fabricate :stage, company: company, projects: [first_project], integration_pipe_id: '123', order: 0, stage_stream: :upstream }
      let(:second_stage) { Fabricate :stage, company: company, projects: [first_project], integration_pipe_id: '123', order: 1, stage_stream: :upstream, end_point: true }

      let!(:first_demand) { Fabricate :demand, project: first_project, demand_id: 'CAVM-1977' }
      let!(:second_demand) { Fabricate :demand, project: first_project, downstream: false }
      let!(:third_demand) { Fabricate :demand, project: first_project, downstream: false }

      let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: first_demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-02-28T17:09:58-03:00' }
      let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: second_demand, last_time_in: '2018-02-20T17:09:58-03:00', last_time_out: '2018-02-23T17:09:58-03:00' }
      let!(:third_transition) { Fabricate :demand_transition, stage: second_stage, demand: third_demand, last_time_in: '2018-04-04T17:09:58-03:00', last_time_out: nil }

      it { expect(DemandTransitionsRepository.instance.summed_transitions_time_grouped_by_stage_demand_for(Demand.all)).to eq(first_stage.name => { data: { first_demand.demand_id => 86_400.0 }, consolidation: 86_400.0 }, second_stage.name => { data: { second_demand.demand_id => 259_200.0, third_demand.demand_id => nil }, consolidation: 259_200.0 }) }
    end

    context 'having no data' do
      it { expect(DemandTransitionsRepository.instance.summed_transitions_time_grouped_by_stage_demand_for(Demand.all)).to eq({}) }
    end
  end

  describe '#hours_per_stage' do
    context 'having transitions' do
      let(:company) { Fabricate :company }
      let(:customer) { Fabricate :customer, company: company }
      let(:project) { Fabricate :project, customer: customer }
      let(:other_project) { Fabricate :project, customer: customer }

      let(:first_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, name: 'first_stage', queue: false, order: 2 }
      let(:second_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, name: 'second_stage', queue: false, order: 1 }
      let(:fourth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :upstream, name: 'fourth_stage', queue: false, order: 0 }

      let(:third_stage) { Fabricate :stage, company: company, projects: [other_project], stage_stream: :downstream, name: 'third_stage', queue: true, order: 4 }
      let(:fifth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, name: 'fifth_stage', queue: true, order: 3 }

      let(:sixth_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, name: 'sixth_stage', end_point: true, order: 5 }

      let!(:seventh_stage) { Fabricate :stage, company: company, projects: [project], stage_stream: :downstream, name: 'seventh_stage', end_point: false, order: 5 }

      let(:demand) { Fabricate :demand, project: project }
      let(:other_demand) { Fabricate :demand, project: other_project }

      let!(:first_transition) { Fabricate :demand_transition, stage: first_stage, demand: demand, last_time_in: '2018-02-27T17:09:58-03:00', last_time_out: '2018-03-02T17:09:58-03:00' }
      let!(:second_transition) { Fabricate :demand_transition, stage: second_stage, demand: demand, last_time_in: '2018-02-02T17:09:58-03:00', last_time_out: '2018-02-09T17:09:58-03:00' }
      let!(:fourth_transition) { Fabricate :demand_transition, stage: fourth_stage, demand: demand, last_time_in: '2018-01-08T17:09:58-03:00', last_time_out: '2018-02-02T17:09:58-03:00' }

      let!(:third_transition) { Fabricate :demand_transition, stage: third_stage, demand: other_demand, last_time_in: '2018-04-02T17:09:58-03:00', last_time_out: '2018-05-15T17:09:58-03:00' }
      let!(:fifth_transition) { Fabricate :demand_transition, stage: fifth_stage, demand: demand, last_time_in: '2018-03-08T17:09:58-03:00', last_time_out: '2018-04-02T17:09:58-03:00' }

      let!(:sixth_transition) { Fabricate :demand_transition, stage: sixth_stage, demand: demand, last_time_in: '2018-03-08T17:09:58-03:00', last_time_out: '2018-04-02T17:09:58-03:00' }

      let!(:seventh_transition) { Fabricate :demand_transition, stage: seventh_stage, demand: demand, last_time_in: '2018-03-08T17:09:58-03:00', last_time_out: nil }

      it { expect(DemandTransitionsRepository.instance.hours_per_stage(Project.all, :upstream, Date.new(2018, 1, 1))).to eq([['fourth_stage', 0, 2_160_000.0]]) }
      it { expect(DemandTransitionsRepository.instance.hours_per_stage(Project.all, :upstream, Date.new(2018, 2, 2))).to eq([]) }

      it { expect(DemandTransitionsRepository.instance.hours_per_stage(Project.all, :downstream, Date.new(2018, 1, 1))).to eq([['second_stage', 1, 604_800.0], ['first_stage', 2, 259_200.0], ['fifth_stage', 3, 2_160_000.0], ['third_stage', 4, 3_715_200.0]]) }
      it { expect(DemandTransitionsRepository.instance.hours_per_stage(Project.all, :downstream, Date.new(2018, 2, 2))).to eq([['second_stage', 1, 604_800.0], ['first_stage', 2, 259_200.0], ['fifth_stage', 3, 2_160_000.0], ['third_stage', 4, 3_715_200.0]]) }
    end

    context 'having no transitions' do
      it { expect(DemandTransitionsRepository.instance.hours_per_stage(Project.all, :upstream, Date.new(2018, 1, 1))).to eq [] }
    end
  end
end
