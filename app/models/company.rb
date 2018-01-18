# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  abbreviation :string           not null
#

class Company < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :financial_informations, dependent: :restrict_with_error
  has_many :customers, dependent: :restrict_with_error
  has_many :products, through: :customers
  has_many :teams, dependent: :restrict_with_error
  has_many :operation_results, dependent: :restrict_with_error

  validates :name, :abbreviation, presence: true

  def outsourcing_cost_per_week
    teams.sum(&:outsourcing_cost_per_week)
  end

  def management_cost_per_week
    teams.sum(&:management_cost_per_week)
  end

  def outsourcing_members_billable_count
    teams.sum(&:outsourcing_members_billable_count)
  end

  def management_count
    teams.sum(&:management_count)
  end

  def active_projects_count
    customers.map(&:active_projects).flatten.count
  end

  def waiting_projects_count
    customers.map(&:waiting_projects).flatten.count
  end

  def red_projects_count
    customers.map(&:red_projects).flatten.count
  end

  def projects_count
    customers.sum(&:projects_count)
  end

  def products_count
    customers.sum(&:products_count)
  end

  def last_cost_per_hour
    finance = financial_informations.order(finances_date: :desc).first
    finance&.cost_per_hour
  end

  def current_backlog
    customers.sum(&:current_backlog)
  end

  def current_outsourcing_monthly_available_hours
    teams.sum(&:current_outsourcing_monthly_available_hours)
  end

  def consumed_hours_in_week(week, year)
    ProjectResultsRepository.instance.consumed_hours_in_week(self, week, year)
  end

  def th_in_week(week, year)
    ProjectResultsRepository.instance.th_in_week(self, week, year)
  end

  def bugs_opened_in_week(week, year)
    ProjectResultsRepository.instance.bugs_opened_in_week(self, week, year)
  end

  def bugs_closed_in_week(week, year)
    ProjectResultsRepository.instance.bugs_closed_in_week(self, week, year)
  end
end
