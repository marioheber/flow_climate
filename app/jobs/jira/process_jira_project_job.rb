# frozen_string_literal: true

module Jira
  class ProcessJiraProjectJob < ApplicationJob
    def perform(jira_account, project_jira_config, user_email, user_name, project_url)
      started_time = Time.zone.now
      project_issues = Jira::JiraApiService.new(jira_account.username, jira_account.password, jira_account.base_uri).request_issues_by_fix_version(project_jira_config.jira_project_key, project_jira_config.fix_version_name)

      project_issues.each do |jira_issue|
        next if jira_issue.attrs['key'].blank?

        jira_issue_with_transitions = Jira::JiraApiService.new(jira_account.username, jira_account.password, jira_account.base_uri).request_issue_details(jira_issue.attrs['key'])
        Jira::JiraIssueAdapter.instance.process_issue!(jira_account, project_jira_config.project, jira_issue_with_transitions)
      end

      finished_time = Time.zone.now
      UserNotifierMailer.sync_finished(user_email, user_name, Project.model_name.human.downcase, project_jira_config.jira_project_key, started_time, finished_time, project_url).deliver
    end
  end
end
