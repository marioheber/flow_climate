# frozen_string_literal: true

# == Schema Information
#
# Table name: project_results
#
#  available_hours        :decimal(, )      not null
#  average_demand_cost    :decimal(, )      not null
#  cost_in_month          :decimal(, )      not null
#  created_at             :datetime         not null
#  demands_count          :integer
#  effort_share_in_month  :decimal(, )
#  flow_pressure          :decimal(, )      not null
#  id                     :bigint(8)        not null, primary key
#  known_scope            :integer          not null
#  leadtime_60_confidence :decimal(, )
#  leadtime_80_confidence :decimal(, )
#  leadtime_95_confidence :decimal(, )
#  leadtime_average       :decimal(, )
#  manual_input           :boolean          default(FALSE)
#  monte_carlo_date       :date
#  project_id             :integer          not null, indexed
#  qty_bugs_closed        :integer          not null
#  qty_bugs_opened        :integer          not null
#  qty_hours_bug          :integer          not null
#  qty_hours_downstream   :integer          not null
#  qty_hours_upstream     :integer          not null
#  remaining_days         :integer          not null
#  result_date            :date             not null
#  team_id                :integer          not null
#  throughput_downstream  :integer          default(0)
#  throughput_upstream    :integer          default(0)
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_project_results_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_b11de7d28e  (team_id => teams.id)
#  fk_rails_c3c9938173  (project_id => projects.id)
#

class ProjectResult < ApplicationRecord
  belongs_to :team
  belongs_to :project
  has_many :demands, dependent: :restrict_with_error

  validates :project, :team, :known_scope, :qty_hours_upstream, :qty_hours_downstream, :qty_hours_bug, :qty_bugs_closed, :qty_bugs_opened,
            :result_date, :cost_in_month, :available_hours, presence: true

  scope :for_week, ->(week, year) { where('EXTRACT(WEEK FROM result_date) = :week AND EXTRACT(YEAR FROM result_date) = :year', week: week, year: year) }
  scope :until_week, ->(week, year) { where('(EXTRACT(WEEK FROM result_date) <= :week AND EXTRACT(YEAR FROM result_date) <= :year) OR (EXTRACT(YEAR FROM result_date) < :year)', week: week, year: year) }
  scope :until_month, ->(month, year) { where('(EXTRACT(MONTH FROM result_date) <= :month AND EXTRACT(YEAR FROM result_date) <= :year) OR (EXTRACT(YEAR FROM result_date) < :year)', month: month, year: year) }
  scope :in_month, ->(target_date) { where('result_date >= :start_date AND result_date <= :end_date', start_date: target_date.beginning_of_month, end_date: target_date.end_of_month) }
  scope :manual_results, -> { left_outer_joins(demands: :demand_transitions).where('demand_transitions.id IS NULL').order(:result_date) }

  delegate :name, to: :team, prefix: true

  validate :result_date_greater_than_project_end_date

  def project_delivered_hours
    qty_hours_upstream + qty_hours_downstream
  end

  def hours_per_demand_upstream
    return 0 if throughput_upstream.zero?
    qty_hours_upstream.to_f / throughput_upstream.to_f
  end

  def hours_per_demand_downstream
    return 0 if throughput_downstream.zero?
    qty_hours_downstream.to_f / throughput_downstream.to_f
  end

  def total_hours
    qty_hours_upstream + qty_hours_downstream
  end

  def add_demand!(demand)
    demands << demand unless demands.include?(demand)
    ProjectResult.reset_counters(id, :demands_count) if id.present?
    demand.update(project_result: self)
    compute_flow_metrics!
  end

  def remove_demand!(demand)
    demand.update(project_result: nil) if demands.include?(demand)
    ProjectResult.reset_counters(id, :demands_count)
    return destroy if demands.count.zero?
    compute_flow_metrics!
  end

  def compute_flow_metrics!
    finished_bugs = demands.finished_bugs.uniq
    open_bugs = demands.bug.opened_in_date(result_date).uniq

    update_result!(delivered_demands_upstream, delivered_demands_downstream, finished_bugs, open_bugs)
  end

  private

  def update_result!(finished_upstream_demands, finished_downstream_demands, finished_bugs, opened_bugs)
    remaining_days = project.remaining_days(result_date)

    update(known_scope: current_scope, throughput_upstream: finished_upstream_demands.count, throughput_downstream: finished_downstream_demands.count, qty_hours_upstream: sum_effort(:effort_upstream),
           qty_hours_downstream: sum_effort(:effort_downstream), qty_hours_bug: finished_bugs.sum(&:effort_downstream), qty_bugs_closed: finished_bugs.count, qty_bugs_opened: opened_bugs.count,
           remaining_days: remaining_days, flow_pressure: current_flow_pressure, average_demand_cost: compute_average_demand_cost(finished_upstream_demands + finished_downstream_demands))

    compute_and_save_leadtimes!
  end

  def compute_and_save_leadtimes!
    demands_leadtime = project.demands.finished_with_leadtime.where('end_date <= :limit_date', limit_date: result_date.end_of_day).map(&:leadtime)
    percentile95 = Stats::StatisticsService.instance.percentile(95, demands_leadtime)
    percentile80 = Stats::StatisticsService.instance.percentile(80, demands_leadtime)
    percentile60 = Stats::StatisticsService.instance.percentile(60, demands_leadtime)
    leadtime_average = Stats::StatisticsService.instance.mean(demands_leadtime)

    update(leadtime_60_confidence: percentile60, leadtime_80_confidence: percentile80, leadtime_95_confidence: percentile95, leadtime_average: leadtime_average)
  end

  def sum_effort(field)
    demands.finished.sum(field)
  end

  def cost_per_day
    return 0 if cost_in_month.blank?
    cost_in_month / 30
  end

  def compute_average_demand_cost(finished_demands = nil)
    throughput_for_result = throughput_upstream + throughput_downstream
    throughput_for_result = finished_demands.count if finished_demands.present?
    return 0 if cost_per_day.zero? || throughput_for_result.zero?
    cost_per_day / throughput_for_result.to_f
  end

  def current_gap
    current_scope - project.total_throughput_until(result_date)
  end

  def current_flow_pressure
    return 0 if project.remaining_days(result_date).zero? || current_gap.to_f <= 0
    current_gap.to_f / project.remaining_days(result_date).to_f
  end

  def result_date_greater_than_project_end_date
    return true if (result_date.blank? || project.start_date.blank?) || (result_date <= project.end_date)
    errors.add(:result_date, I18n.t('project_result.validations.result_date_greater_than_project_start_date'))
  end

  def current_scope
    DemandsRepository.instance.known_scope_to_date(project, result_date) + project.initial_scope
  end

  def delivered_demands_upstream
    valid_demands = demands.not_discarded_until_date(result_date)
    valid_demands.finished_in_stream(Stage.stage_streams[:upstream]) | valid_demands.finished.upstream_flag
  end

  def delivered_demands_downstream
    valid_demands = demands.not_discarded_until_date(result_date)
    (valid_demands.finished_in_stream(Stage.stage_streams[:downstream]) | valid_demands.finished.downstream_flag) - delivered_demands_upstream
  end
end
