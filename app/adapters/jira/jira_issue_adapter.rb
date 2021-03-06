# frozen_string_literal: true

module Jira
  class JiraIssueAdapter < BaseFlowAdapter
    include Singleton

    def process_issue!(jira_account, project, jira_issue)
      issue_key = jira_issue.attrs['key']
      return if issue_key.blank?

      demand = Demand.where(company_id: project.company.id, demand_id: issue_key).first_or_initialize

      update_demand!(demand, jira_account, jira_issue, project)

      demand
    end

    private

    def update_demand!(demand, jira_account, jira_issue, project)
      demand.update(project: project, company: project.company, created_date: issue_fields_value(jira_issue, 'created'), demand_type: translate_issue_type(jira_issue), artifact_type: translate_artifact_type(jira_issue),
                    class_of_service: translate_class_of_service(jira_account, jira_issue), demand_title: issue_fields_value(jira_issue, 'summary'),
                    assignees_count: compute_assignees_count(jira_account, jira_issue), url: build_jira_url(jira_account, demand.demand_id), downstream: false, discarded_at: nil)

      translate_blocks!(demand, jira_issue)
      process_transitions!(demand, jira_issue.changelog) if jira_issue.respond_to?(:changelog)
    end

    def issue_fields_value(jira_issue, field_name)
      jira_issue.attrs['fields'][field_name]
    end

    def translate_issue_type(jira_issue)
      issue_type_name = jira_issue.attrs['fields']['issuetype']['name']
      return :feature if check_feature(issue_type_name)
      return :chore if issue_type_name.casecmp('chore').zero?
      return :performance_improvement if issue_type_name.casecmp('performance improvement').zero?
      return :wireframe if issue_type_name.casecmp('wireframes').zero?
      return :ui if issue_type_name.casecmp('ui').zero?

      :bug
    end

    def check_feature(issue_type_name)
      issue_type_name.casecmp('story').zero? || issue_type_name.casecmp('epic').zero? || issue_type_name.casecmp('feature').zero?
    end

    def translate_artifact_type(jira_issue)
      issue_type_name = jira_issue.attrs['fields']['issuetype']['name']
      return :epic if issue_type_name.casecmp('epic').zero?

      :story
    end

    def translate_class_of_service(jira_account, jira_issue)
      class_of_service_custom_field_name = jira_account.class_of_service_custom_field&.custom_field_machine_name
      return :standard if class_of_service_custom_field_name.blank?

      class_of_service_hash = jira_issue.attrs['fields'][class_of_service_custom_field_name]
      return :standard if class_of_service_hash.blank?

      class_of_service = class_of_service_hash['value']

      if class_of_service.casecmp('expedite').zero?
        :expedite
      elsif class_of_service.casecmp('fixed date').zero?
        :fixed_date
      elsif class_of_service.casecmp('intangible').zero?
        :intangible
      else
        :standard
      end
    end

    def compute_assignees_count(jira_account, jira_issue)
      responsibles_custom_field_name = jira_account.responsibles_custom_field&.custom_field_machine_name
      return 1 if responsibles_custom_field_name.blank?

      responsibles = jira_issue.attrs['fields'][responsibles_custom_field_name]

      return 1 if responsibles.blank?

      responsibles.count
    end

    def translate_blocks!(demand, jira_issue)
      return unless hash_have_histories?(jira_issue)

      history_array = jira_issue.attrs['changelog']['histories']

      demand.demand_blocks.map(&:destroy)

      history_array.sort_by { |history_hash| Time.zone.parse(history_hash['created']) }.each do |history|
        next if history['items'].blank?

        history_item = history['items'][0]
        next unless impediment_field?(history_item)

        process_demand_block(demand, history, history_item)
      end
    end

    def impediment_field?(history_item)
      history_item['field'].casecmp('impediment').zero? || history_item['field'].casecmp('flagged').zero?
    end

    def hash_have_histories?(jira_issue)
      jira_issue.attrs['changelog'].present? && jira_issue.attrs['changelog']['histories'].present?
    end

    def process_demand_block(demand, history, history_item)
      created = history['created']
      author = history['author']['displayName']

      if history_item['toString'].casecmp('impediment').zero? || history_item['toString'].casecmp('impedimento').zero?
        persist_block!(demand, author, created)
      elsif history_item['fromString'].casecmp('impediment').zero? || history_item['fromString'].casecmp('impedimento').zero?
        persist_unblock!(demand, author, created)
      end
    end

    def process_transitions!(demand, issue_changelog)
      demand.demand_transitions.map(&:destroy)

      last_time_out = demand.created_date
      issue_changelog['histories'].sort_by { |history_hash| history_hash['id'] }.each do |history|
        next unless transition_history?(history)

        transition_created_at = history['created']
        create_transitions!(demand, history, last_time_out, transition_created_at)
        last_time_out = transition_created_at
      end
    end

    def create_transitions!(demand, history, last_time_out, transition_created_at)
      stage_from = demand.project.stages.find_by(integration_id: from_id(history))
      stage_to = demand.project.stages.find_by(integration_id: to_id(history))

      transition_from = DemandTransition.where(demand: demand, stage: stage_from).first_or_initialize
      transition_from.update(last_time_in: last_time_out, last_time_out: transition_created_at)

      transition_to = DemandTransition.where(demand: demand, stage: stage_to).first_or_initialize
      transition_to.update(demand: demand, last_time_in: transition_created_at, last_time_out: nil)
    end

    def to_id(history)
      history['items'].first['to']
    end

    def from_id(history)
      history['items'].first['from']
    end

    def transition_history?(history)
      history['items'].present? && history['items'].first['field'].casecmp('status').zero?
    end

    def build_jira_url(jira_account, issue_key)
      "#{jira_account.base_uri}browse/#{issue_key}"
    end
  end
end
