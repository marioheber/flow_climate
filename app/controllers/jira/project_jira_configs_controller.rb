# frozen_string_literal: true

module Jira
  class ProjectJiraConfigsController < AuthenticatedController
    before_action :assign_company
    before_action :assign_project

    def new
      @project_jira_config = ProjectJiraConfig.new
      respond_to { |format| format.js }
    end

    def create
      team = Team.find_by(id: project_jira_config_params[:team])
      @project_jira_config = ProjectJiraConfig.new(project_jira_config_params.merge(project: @project, team: team))
      @project_jira_config.save
      render 'jira/project_jira_configs/create'
    end

    def destroy
      @project_jira_config = ProjectJiraConfig.find(params[:id])
      @project_jira_config.destroy
      render 'jira/project_jira_configs/destroy'
    end

    private

    def project_jira_config_params
      params.require(:jira_project_jira_config).permit(:jira_account_domain, :jira_project_key, :fix_version_name, :team)
    end

    def assign_project
      @project = Project.find(params[:project_id])
    end
  end
end
