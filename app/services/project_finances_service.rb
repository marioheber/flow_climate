# frozen_string_literal: true

class ProjectFinancesService
  include Singleton

  def effort_share_in_month(project, date)
    team = project.current_team
    return 0 if team.blank?

    other_project_in_team = team.product_projects - [project]

    compute_effort_share(date, other_project_in_team, project)
  end

  private

  def compute_effort_share(date, other_projects_in_team, project)
    total_effort_project = total_effort_to_month([project], project.start_date, date.year, date.month)
    total_effort_other_team_projects = total_effort_to_month(other_projects_in_team, other_projects_in_team.map(&:start_date).min, date.year, date.month)
    Stats::StatisticsService.instance.compute_percentage(total_effort_project, total_effort_other_team_projects) / 100
  end

  def total_effort_to_month(projects, start_date, year, month)
    amount_effort_upstream_project = DemandsRepository.instance.effort_upstream_grouped_by_month(projects, start_date)[[year.to_f, month.to_f]] || 0
    amount_effort_downstream_project = DemandsRepository.instance.grouped_by_effort_downstream_per_month(projects, start_date)[[year.to_f, month.to_f]] || 0
    amount_effort_upstream_project + amount_effort_downstream_project
  end
end
