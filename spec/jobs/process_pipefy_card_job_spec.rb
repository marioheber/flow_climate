# frozen_string_literal: true

RSpec.describe ProcessPipefyCardJob, type: :active_job do
  describe '.perform_later' do
    it 'enqueues after calling perform_later' do
      ProcessPipefyCardJob.perform_later(bla: 'foo')
      expect(ProcessPipefyCardJob).to have_been_enqueued.on_queue('default')
    end
  end

  context 'having no params' do
    it 'returns doing nothing' do
      expect_any_instance_of(ProcessPipefyCardJob).to receive(:process_card).never
      ProcessPipefyCardJob.perform_now({})
    end
  end
  context 'having params' do
    let(:project) { Fabricate :project, end_date: 2.days.from_now }
    let(:card_response) { { data: { card: { id: '4648391', title: 'teste 2', assignees: [], comments: [], comments_count: 0, current_phase: { name: 'Concluído' }, done: true, due_date: nil, fields: [{ name: 'O quê?', value: 'teste 2' }, { name: 'Type', value: 'Bug' }], labels: [{ name: 'BUG' }], phases_history: [{ phase: { id: '2481594', name: 'Start form', done: false, fields: [{ label: 'O quê?' }, { label: 'Type' }] }, firstTimeIn: '2018-01-16T22:44:57-02:00', lastTimeOut: '2018-01-16T22:44:57-02:00' }, { phase: { id: '2481595', name: 'Caixa de entrada', done: false, fields: [{ label: 'Commitment Point?' }] }, firstTimeIn: '2018-01-16T22:44:57-02:00', lastTimeOut: '2018-01-16T23:01:46-02:00' }, { phase: { id: '2481596', name: 'Fazendo', done: false, fields: [{ label: 'Commitment Point?' }] }, firstTimeIn: '2018-01-16T23:01:46-02:00', lastTimeOut: '2018-02-11T17:43:22-02:00' }, { phase: { id: '2481597', name: 'Concluído', done: true, fields: [] }, firstTimeIn: '2018-02-09T01:01:41-02:00', lastTimeOut: nil }], pipe: { id: '356528' }, url: 'http://app.pipefy.com/pipes/356528#cards/4648391' } } }.with_indifferent_access }
    let(:pipe_response) { { data: { pipe: { phases: [{ cards: { edges: [{ node: { id: '4648389', title: 'ateste' } }] } }, { cards: { edges: [] } }, { cards: { edges: [{ node: { id: '4648391', title: 'teste 2' } }] } }] } } }.with_indifferent_access }
    let(:headers) { { Authorization: "Bearer #{Figaro.env.pipefy_token}" } }
    let(:params) { { data: { action: 'card.done', done_by: { id: 101_381, name: 'Foo Bar', username: 'foo', email: 'foo@bar.com', avatar_url: 'gravatar' }, card: { id: 4_648_391, pipe_id: '5fc4VmAE' } } }.with_indifferent_access }

    before do
      stub_request(:post, 'https://app.pipefy.com/queries').with(headers: headers, body: /4648391/).to_return(status: 200, body: card_response.to_json, headers: {})
      stub_request(:post, 'https://app.pipefy.com/queries').with(headers: headers, body: /356528/).to_return(status: 200, body: pipe_response.to_json, headers: {})
    end

    context 'and a pipe config' do
      let(:team) { Fabricate :team }
      let!(:pipefy_config) { Fabricate :pipefy_config, project: project, team: team, pipe_id: '356528' }

      context 'when there is no demand and project result' do
        it 'creates the demand the project_result for the card end_date' do
          ProcessPipefyCardJob.perform_now(params)

          created_demand = Demand.last
          expect(created_demand.demand_id).to eq '4648391'
          expect(created_demand.demand_type).to eq 'bug'
          expect(created_demand.effort.to_f).to eq 144.0
          expect(created_demand.commitment_date).to eq Time.iso8601('2018-01-16T23:01:46-02:00')
          expect(created_demand.end_date).to eq Time.iso8601('2018-02-09T01:01:41-02:00')

          created_project_result = ProjectResult.last
          expect(created_project_result.demands).to eq [created_demand]
          expect(created_project_result.project).to eq project
          expect(created_project_result.team).to eq team
          expect(created_project_result.result_date).to eq Time.iso8601('2018-02-09T01:01:41-02:00').to_date
          expect(created_project_result.known_scope).to eq 2
          expect(created_project_result.throughput).to eq 1
          expect(created_project_result.qty_hours_upstream).to eq 0
          expect(created_project_result.qty_hours_downstream).to eq 144.0
          expect(created_project_result.qty_hours_bug).to eq 144.0
          expect(created_project_result.qty_bugs_closed).to eq 1
          expect(created_project_result.qty_bugs_opened).to eq 0
          expect(created_project_result.flow_pressure.to_f).to eq 0.5
          expect(created_project_result.remaining_days).to eq project.remaining_days
          expect(created_project_result.cost_in_week).to eq team.outsourcing_cost / 4
          expect(created_project_result.average_demand_cost).to eq team.outsourcing_cost / 4
          expect(created_project_result.available_hours).to eq team.current_outsourcing_monthly_available_hours
        end
      end

      context 'when there is a project result and an another demand in this project result' do
        let(:project_result) { Fabricate :project_result, project: project, result_date: Time.iso8601('2018-02-09T01:01:41-02:00').to_date, team: team, known_scope: 1, throughput: 1, qty_hours_upstream: 30, qty_hours_downstream: 130, qty_hours_bug: 23, qty_bugs_closed: 2, qty_bugs_opened: 4, cost_in_week: 100, available_hours: 30, remaining_days: 2 }
        let!(:demand) { Fabricate :demand, demand_type: :feature, project_result: project_result, end_date: Time.iso8601('2018-02-09T01:01:41-02:00').to_date, effort: 100 }

        it 'creates the new demand and updates the project result' do
          ProcessPipefyCardJob.perform_now(params)

          expect(Demand.count).to eq 2

          created_demand = Demand.last
          expect(created_demand.demand_id).to eq '4648391'
          expect(created_demand.demand_type).to eq 'bug'
          expect(created_demand.effort.to_f).to eq 144.0
          expect(created_demand.commitment_date).to eq Time.iso8601('2018-01-16T23:01:46-02:00')
          expect(created_demand.end_date).to eq Time.iso8601('2018-02-09T01:01:41-02:00')

          expect(ProjectResult.count).to eq 1

          updated_project_result = ProjectResult.last
          expect(updated_project_result.demands).to match_array [demand, created_demand]
          expect(updated_project_result.project).to eq project
          expect(updated_project_result.team).to eq team
          expect(updated_project_result.result_date).to eq Time.iso8601('2018-02-09T01:01:41-02:00').to_date
          expect(updated_project_result.known_scope).to eq 2
          expect(updated_project_result.throughput).to eq 2
          expect(updated_project_result.qty_hours_upstream).to eq 0
          expect(updated_project_result.qty_hours_downstream).to eq 244
          expect(updated_project_result.qty_hours_bug).to eq 144.0
          expect(updated_project_result.qty_bugs_closed).to eq 1
          expect(updated_project_result.qty_bugs_opened).to eq 0
          expect(updated_project_result.flow_pressure.to_f).to eq 1
          expect(updated_project_result.remaining_days).to eq 2
          expect(updated_project_result.cost_in_week.to_f).to eq 100
          expect(updated_project_result.average_demand_cost.to_f).to eq 50.0
          expect(updated_project_result.available_hours.to_f).to eq 30
        end
      end

      context 'when the project result and the demand already exists' do
        context 'in the same project result' do
          let(:project_result) { Fabricate :project_result, project: project, result_date: Time.iso8601('2018-02-09T01:01:41-02:00').to_date, team: team, known_scope: 1, throughput: 1, qty_hours_upstream: 30, qty_hours_downstream: 130, qty_hours_bug: 23, qty_bugs_closed: 2, qty_bugs_opened: 4, cost_in_week: 100, available_hours: 30, remaining_days: 2 }
          let!(:demand) { Fabricate :demand, demand_id: '4648391', project_result: project_result, end_date: Time.iso8601('2018-02-07T01:01:41-02:00').to_date }

          it 'updates the demand and the project result' do
            ProcessPipefyCardJob.perform_now(params)

            expect(Demand.count).to eq 1

            updated_demand = Demand.last
            expect(updated_demand.demand_id).to eq '4648391'
            expect(updated_demand.demand_type).to eq 'bug'
            expect(updated_demand.effort.to_f).to eq 144.0
            expect(updated_demand.commitment_date).to eq Time.iso8601('2018-01-16T23:01:46-02:00')
            expect(updated_demand.end_date).to eq Time.iso8601('2018-02-09T01:01:41-02:00')

            expect(ProjectResult.count).to eq 1

            updated_project_result = ProjectResult.last
            expect(updated_project_result.demands).to match_array [demand]
            expect(updated_project_result.project).to eq project
            expect(updated_project_result.team).to eq team
            expect(updated_project_result.result_date).to eq Time.iso8601('2018-02-09T01:01:41-02:00').to_date
            expect(updated_project_result.known_scope).to eq 2
            expect(updated_project_result.throughput).to eq 1
            expect(updated_project_result.qty_hours_upstream).to eq 0
            expect(updated_project_result.qty_hours_downstream).to eq 144
            expect(updated_project_result.qty_hours_bug).to eq 144.0
            expect(updated_project_result.qty_bugs_closed).to eq 1
            expect(updated_project_result.qty_bugs_opened).to eq 0
            expect(updated_project_result.flow_pressure.to_f).to eq 0.5
            expect(updated_project_result.remaining_days).to eq 2
            expect(updated_project_result.cost_in_week.to_f).to eq 100
            expect(updated_project_result.average_demand_cost.to_f).to eq 100.0
            expect(updated_project_result.available_hours.to_f).to eq 30
          end
        end

        context 'in another project result' do
          let!(:project_result) { Fabricate :project_result, project: project, result_date: Time.iso8601('2018-02-09T01:01:41-02:00').to_date, team: team, known_scope: 1, throughput: 1, qty_hours_upstream: 30, qty_hours_downstream: 130, qty_hours_bug: 23, qty_bugs_closed: 2, qty_bugs_opened: 4, cost_in_week: 100, available_hours: 30, remaining_days: 2 }
          let!(:other_project_result) { Fabricate :project_result, project: project, result_date: Time.iso8601('2018-02-07T01:01:41-02:00').to_date, team: team, known_scope: 1, throughput: 1, qty_hours_upstream: 30, qty_hours_downstream: 130, qty_hours_bug: 23, qty_bugs_closed: 2, qty_bugs_opened: 4, cost_in_week: 100, available_hours: 30, remaining_days: 2 }
          let!(:demand) { Fabricate :demand, demand_id: '4648391', project_result: other_project_result, end_date: Time.iso8601('2018-02-07T01:01:41-02:00').to_date }

          it 'updates the demand and move it from a project result to the new one' do
            ProcessPipefyCardJob.perform_now(params)
            expect(Demand.count).to eq 1
            expect(demand.reload.project_result).to eq project_result
            expect(other_project_result.reload.demands).to eq []
          end
        end
      end
    end
  end
end