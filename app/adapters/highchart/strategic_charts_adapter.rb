# frozen_string_literal: true

module Highchart
  class StrategicChartsAdapter
    attr_reader :company, :array_of_months, :active_projects_count_data, :sold_hours_in_month, :consumed_hours_per_month, :available_hours_per_month,
                :flow_pressure_per_month_data, :money_per_month_data, :expenses_per_month_data

    def initialize(company, projects, total_available_hours)
      @company = company
      @array_of_months = []
      @active_projects_count_data = []
      @sold_hours_in_month = []
      @consumed_hours_per_month = []
      @available_hours_per_month = []
      @flow_pressure_per_month_data = []
      @money_per_month_data = []
      @expenses_per_month_data = []

      assign_attributes(projects, total_available_hours)
    end

    private

    def assign_attributes(projects, total_available_hours)
      assign_months_by_projects_dates(projects)
      assign_active_projects_count_data(projects)
      assign_sold_hours_per_month(projects)
      assign_consumed_hours_per_month(projects)
      assign_available_hours_per_month(total_available_hours)
      assign_flow_pressure_per_month_data(projects)
      assign_money_per_month_data(projects)
      assign_expenses_per_month_data
    end

    def assign_consumed_hours_per_month(projects)
      @array_of_months.each do |month_year|
        @consumed_hours_per_month << ProjectsRepository.instance.hours_consumed_per_month(projects, Date.new(month_year[1], month_year[0], 1))
      end
    end

    def assign_available_hours_per_month(available_hours)
      @array_of_months.each do
        @available_hours_per_month << available_hours
      end
    end

    def assign_sold_hours_per_month(projects)
      @array_of_months.each do |month_year|
        @sold_hours_in_month << ProjectsRepository.instance.active_projects_in_month(projects, Date.new(month_year[1], month_year[0], 1)).sum(&:hours_per_month)
      end
    end

    def assign_active_projects_count_data(projects)
      @array_of_months.each do |month_year|
        @active_projects_count_data << ProjectsRepository.instance.active_projects_in_month(projects, Date.new(month_year[1], month_year[0], 1)).count
      end
    end

    def assign_flow_pressure_per_month_data(projects)
      @array_of_months.each do |month_year|
        @flow_pressure_per_month_data << ProjectsRepository.instance.flow_pressure_to_month(projects, Date.new(month_year[1], month_year[0], 1))
      end
    end

    def assign_money_per_month_data(projects)
      @array_of_months.each do |month_year|
        @money_per_month_data << ProjectsRepository.instance.money_to_month(projects, Date.new(month_year[1], month_year[0], 1)).to_f
      end
    end

    def assign_expenses_per_month_data
      last_expense = 0
      @array_of_months.each do |month_year|
        expenses_in_month = @company.financial_informations.for_month(month_year[0], month_year[1]).first&.expenses_total&.to_f || last_expense
        @expenses_per_month_data << expenses_in_month
        last_expense = expenses_in_month
      end
    end

    def assign_months_by_projects_dates(projects)
      min_date = projects.running.minimum(:start_date)
      max_date = projects.running.maximum(:end_date)

      return if max_date.blank? || min_date.blank?

      while min_date <= max_date
        @array_of_months << [min_date.month, min_date.year]
        min_date += 1.month
      end
    end
  end
end
