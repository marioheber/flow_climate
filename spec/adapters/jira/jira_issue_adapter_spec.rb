# frozen_string_literal: true

RSpec.describe Jira::JiraIssueAdapter, type: :service do
  let(:company) { Fabricate :company }

  let(:options) { { username: 'foo', password: 'bar', site: 'http://foo.bar', context_path: '/', auth_type: :basic, read_timeout: 120 } }
  let(:client) { JIRA::Client.new(options) }

  let(:jira_account) { Fabricate :jira_account, base_uri: 'http://foo.bar', username: 'foo', password: 'bar' }

  let(:customer) { Fabricate :customer, company: company }
  let(:team) { Fabricate :team, company: company }
  let(:product) { Fabricate :product, customer: customer, team: team }

  let!(:first_project) { Fabricate :project, customer: customer, product: product }

  let!(:first_stage) { Fabricate :stage, company: company, integration_id: 'first_stage', projects: [first_project] }
  let!(:second_stage) { Fabricate :stage, company: company, integration_id: 'second_stage', projects: [first_project] }
  let!(:third_stage) { Fabricate :stage, company: company, integration_id: 'third_stage', projects: [first_project] }

  describe '#process_issue!' do
    context 'when the demand does not exist' do
      let!(:jira_account) { Fabricate :jira_account, company: company }
      let!(:responsible_custom_field) { Fabricate :jira_custom_field_mapping, jira_account: jira_account, demand_field: :responsibles, custom_field_machine_name: 'customfield_10024' }
      let!(:class_of_service_custom_field) { Fabricate :jira_custom_field_mapping, jira_account: jira_account, demand_field: :class_of_service, custom_field_machine_name: 'customfield_10028' }

      context 'and it is a feature' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', fields: { created: '2018-07-02T11:20:18.998-0300', summary: 'foo of bar', issuetype: { name: 'Story' }, customfield_10028: { value: 'Expedite' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }] }, changelog: { startAt: 0, maxResults: 2, total: 2, histories: [{ id: '10039', created: '2018-07-08T22:34:47.440-0300', items: [{ field: 'status', from: 'first_stage', to: 'second_stage' }] }, { id: '10038', created: '2018-07-06T09:40:43.886-0300', items: [{ field: 'status', from: 'third_stage', to: 'first_stage' }] }] } }.with_indifferent_access) }

        it 'creates the demand' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.count).to eq 1
          expect(Demand.last.assignees_count).to eq 2
          expect(Demand.last.demand_title).to eq 'foo of bar'
          expect(Demand.last.downstream).to be false
          expect(Demand.last).to be_feature
          expect(Demand.last).to be_expedite
          expect(Demand.last.created_date).to eq Time.zone.parse('2018-07-02T11:20:18.998-0300')

          expect(DemandTransition.count).to eq 3

          first_stage_updated = first_stage.reload
          expect(first_stage_updated.demand_transitions.count).to eq 1
          expect(first_stage_updated.demand_transitions.first.last_time_in).to eq Time.zone.parse('2018-07-06T09:40:43.886-0300')
          expect(first_stage_updated.demand_transitions.first.last_time_out).to eq Time.zone.parse('2018-07-08T22:34:47.440-0300')

          second_stage_updated = second_stage.reload
          expect(second_stage_updated.demand_transitions.count).to eq 1
          expect(second_stage_updated.demand_transitions.first.last_time_in).to eq Time.zone.parse('2018-07-08T22:34:47.440-0300')
          expect(second_stage_updated.demand_transitions.first.last_time_out).to be_nil

          third_stage_updated = third_stage.reload
          expect(third_stage_updated.demand_transitions.count).to eq 1
          expect(third_stage_updated.demand_transitions.first.last_time_in).to eq Time.zone.parse('2018-07-02T11:20:18.998-0300')
          expect(third_stage_updated.demand_transitions.first.last_time_out).to eq Time.zone.parse('2018-07-06T09:40:43.886-0300')
        end
      end
      context 'and it is a bug' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'Bug' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }] } }.with_indifferent_access) }
        it 'creates the demand' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.last).to be_bug
        end
      end
      context 'and it is a feature' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'FeaTurE' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }] } }.with_indifferent_access) }
        it 'creates the demand' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.last).to be_feature
        end
      end
      context 'and it is a chore and no class of service' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'ChoRe' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }] } }.with_indifferent_access) }
        it 'creates the demand as chore as type and standard as class of service' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.last).to be_chore
          expect(Demand.last).to be_standard
        end
      end
      context 'and it is an epic' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'ePIc' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }] } }.with_indifferent_access) }
        it 'creates the demand as chore as type and standard as class of service' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.last).to be_feature
          expect(Demand.last).to be_epic
        end
      end
      context 'and it is a class of service fixed date' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'fixed date' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }], customfield_10028: { value: 'FixEd DatE' } } }.with_indifferent_access) }
        it 'creates the demand as fixed date class of service' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.last).to be_fixed_date
        end
      end
      context 'and it is a class of service intangible' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'Chore' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }], customfield_10028: { value: 'intangible' } } }.with_indifferent_access) }
        it 'creates the demand as intangible class of service' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.last).to be_intangible
        end
      end
      context 'and it is a class of service standard' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'chore' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }], customfield_10028: { value: 'sTandard' } } }.with_indifferent_access) }
        it 'creates the demand as standard class of service' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.last).to be_standard
        end
      end

      context 'and it was blocked' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-03T11:20:18.998-0300', issuetype: { name: 'chore' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }], customfield_10028: { value: 'sTandard' } }, changelog: { comment: { comments: [{ body: '(flagoff) o bla do xpto foi resolvido de boa', created: '2018-07-07T17:00:18.399-0300', author: { name: 'bla' } }, { body: '(flag) Flag added\n\nbla do xpto passando pelo foo até o bar.', created: '2018-07-06T17:00:18.399-0300', author: { name: 'sbbrubles' } }, { body: '(flag) Flag added\n\nbla do xpto resolvido nada.. vai ter que refazer essa bagaça..', created: '2018-07-08T17:00:18.399-0300', author: { name: 'soul' } }, { body: 'Comentário que não é um bloqueio modafucka', created: '2018-07-09T17:00:18.399-0300', author: { name: 'mor' } }] }, histories: [{ id: '10038', author: { displayName: 'bla' }, created: '2018-07-06T09:40:43.886-0300', items: [{ field: 'Impediment', fromString: '', to: '10055', toString: 'Impediment' }] }, { id: '10055', author: { displayName: 'xpto' }, created: '2018-07-06T13:40:43.886-0300', items: [{ field: 'Impediment', fromString: 'Impediment', to: '10055', toString: '' }] }, { id: '10055', author: { displayName: 'foo' }, created: '2018-07-09T13:40:43.886-0300', items: [{ field: 'Impediment', fromString: '', to: '10055', toString: 'Impediment' }] }] } }.with_indifferent_access) }

        it 'creates the demand and the blocks information' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          demand_created = Demand.last
          expect(demand_created.demand_blocks.count).to eq 2

          first_demand_block = demand_created.demand_blocks.order(created_at: :asc).first
          expect(first_demand_block.blocker_username).to eq 'bla'
          expect(first_demand_block.block_time).to eq '2018-07-06T09:40:43.886000000-0300'

          expect(first_demand_block.unblocker_username).to eq 'xpto'
          expect(first_demand_block.unblock_time).to eq '2018-07-06T13:40:43.886-0300'

          second_demand_block = demand_created.demand_blocks.second
          expect(second_demand_block.blocker_username).to eq 'foo'
          expect(second_demand_block.block_time).to eq '2018-07-09T13:40:43.886-0300'

          expect(second_demand_block.unblocker_username).to be_nil
          expect(second_demand_block.unblock_time).to be_nil
        end
      end

      context 'and the issue returned to a previous stage and went forward again' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', summary: 'foo of bar', fields: { created: '2018-07-02T11:20:18.998-0300', issuetype: { name: 'Story' }, customfield_10028: { value: 'Expedite' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }] }, changelog: { startAt: 0, maxResults: 2, total: 2, histories: [{ id: '10041', created: '2018-07-09T23:34:47.440-0300', items: [{ field: 'status', from: 'first_stage', to: 'second_stage' }] }, { id: '10040', created: '2018-07-09T22:34:47.440-0300', items: [{ field: 'status', from: 'second_stage', to: 'first_stage' }] }, { id: '10039', created: '2018-07-08T22:34:47.440-0300', items: [{ field: 'status', from: 'first_stage', to: 'second_stage' }] }, { id: '10038', created: '2018-07-06T09:40:43.886-0300', items: [{ field: 'status', from: 'third_stage', to: 'first_stage' }] }, { id: '10055', created: '2018-07-06T09:40:43.886-0300', items: [{ field: 'foo', from: 'third_stage', to: 'first_stage' }] }] } }.with_indifferent_access) }
        it 'creates the demand and the transitions using the last time it passed in the stage' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)

          expect(DemandTransition.count).to eq 3

          first_stage_updated = first_stage.reload
          expect(first_stage_updated.demand_transitions.count).to eq 1
          expect(first_stage_updated.demand_transitions.first.last_time_in).to eq Time.zone.parse('2018-07-09T22:34:47.440-0300')
          expect(first_stage_updated.demand_transitions.first.last_time_out).to eq Time.zone.parse('2018-07-09T23:34:47.440-0300')

          second_stage_updated = second_stage.reload
          expect(second_stage_updated.demand_transitions.count).to eq 1
          expect(second_stage_updated.demand_transitions.first.last_time_in).to eq Time.zone.parse('2018-07-09T23:34:47.440-0300')
          expect(second_stage_updated.demand_transitions.first.last_time_out).to be_nil

          third_stage_updated = third_stage.reload
          expect(third_stage_updated.demand_transitions.count).to eq 1
          expect(third_stage_updated.demand_transitions.first.last_time_in).to eq Time.zone.parse('2018-07-02T11:20:18.998-0300')
          expect(third_stage_updated.demand_transitions.first.last_time_out).to eq Time.zone.parse('2018-07-06T09:40:43.886-0300')
        end
      end
    end

    context 'when the demand exists' do
      let!(:jira_account) { Fabricate :jira_account, company: company }
      let!(:jira_custom_field_mapping) { Fabricate :jira_custom_field_mapping, jira_account: jira_account, demand_field: :responsibles, custom_field_machine_name: 'customfield_10024' }
      let!(:demand) { Fabricate :demand, project: first_project, demand_id: '10000' }

      let!(:jira_issue) { client.Issue.build({ key: '10000', fields: { created: '2018-07-02T11:20:18.998-0300', summary: 'foo of bar', issuetype: { name: 'Story' }, customfield_10028: { value: 'Expedite' }, project: { key: 'foo' }, customfield_10024: [{ name: 'foo' }, { name: 'bar' }] }, changelog: { startAt: 0, maxResults: 2, total: 2, histories: [{ id: '10039', from: 'first_stage', to: 'second_stage', created: '2018-07-08T22:34:47.440-0300' }, { id: '10038', from: 'third_stage', to: 'first_stage', created: '2018-07-06T09:40:43.886-0300' }] } }.with_indifferent_access) }

      context 'and the demand is not archived' do
        it 'updates the demand' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.count).to eq 1
          expect(Demand.last.assignees_count).to eq 2
          expect(Demand.last.demand_title).to eq 'foo of bar'
          expect(Demand.last.downstream).to be false
          expect(Demand.last.url).to eq "#{jira_account.base_uri}browse/10000"
          expect(Demand.last.created_date).to eq Time.zone.parse('2018-07-02T11:20:18.998-0300')
        end
      end
      context 'and the demand was archived' do
        let!(:archived_stage) { Fabricate :stage, stage_type: :archived, projects: [first_project] }
        let!(:archived_demand_transition) { Fabricate :demand_transition, stage: archived_stage, demand: demand }

        it 'updates the demand' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.count).to eq 1
          expect(Demand.last.assignees_count).to eq 2
          expect(Demand.last.demand_title).to eq 'foo of bar'
          expect(Demand.last.downstream).to be false
          expect(Demand.last.url).to eq "#{jira_account.base_uri}browse/10000"
          expect(Demand.last.created_date).to eq Time.zone.parse('2018-07-02T11:20:18.998-0300')
        end
      end

      context 'and the demand was discarded' do
        let!(:discarded_demand) { Fabricate :demand, project: first_project, demand_id: '10010', discarded_at: Time.zone.yesterday }
        let!(:jira_issue) { client.Issue.build({ key: '10010', fields: { created: '2018-07-02T11:20:18.998-0300', summary: 'foo of bar', issuetype: { name: 'Story' }, customfield_10028: { value: 'Expedite' }, project: { key: 'foo' } }, changelog: { startAt: 0, maxResults: 2, total: 2, histories: [{ id: '10039', from: 'first_stage', to: 'second_stage', created: '2018-07-08T22:34:47.440-0300' }, { id: '10038', from: 'third_stage', to: 'first_stage', created: '2018-07-06T09:40:43.886-0300' }] } }.with_indifferent_access) }
        before { Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue) }
        it { expect(discarded_demand.reload.discarded_at).to be nil }
      end

      context 'and there is config to the custom responsibles field and the json does not have the field' do
        let!(:jira_issue) { client.Issue.build({ key: '10000', fields: { created: '2018-07-02T11:20:18.998-0300', summary: 'foo of bar', issuetype: { name: 'Story' }, customfield_10028: { value: 'Expedite' }, project: { key: 'foo' } }, changelog: { startAt: 0, maxResults: 2, total: 2, histories: [{ id: '10039', from: 'first_stage', to: 'second_stage', created: '2018-07-08T22:34:47.440-0300' }, { id: '10038', from: 'third_stage', to: 'first_stage', created: '2018-07-06T09:40:43.886-0300' }] } }.with_indifferent_access) }
        it 'updates the demand throwing no errors' do
          Jira::JiraIssueAdapter.instance.process_issue!(jira_account, first_project, jira_issue)
          expect(Demand.count).to eq 1
          expect(Demand.last.assignees_count).to eq 1
          expect(Demand.last.demand_title).to eq 'foo of bar'
          expect(Demand.last.downstream).to be false
          expect(Demand.last.created_date).to eq Time.zone.parse('2018-07-02T11:20:18.998-0300')
        end
      end
    end
  end
end
