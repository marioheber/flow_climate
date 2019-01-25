# frozen_string_literal: true

class DemandsController < AuthenticatedController
  before_action :user_gold_check

  before_action :assign_company
  before_action :assign_project, except: %i[demands_csv demands_in_projects search_demands_by_flow_status]
  before_action :assign_projects_for_queries, only: %i[demands_in_projects search_demands_by_flow_status]
  before_action :assign_demand, only: %i[edit update show synchronize_jira destroy]

  def new
    @demand = Demand.new(project: @project)
  end

  def create
    @demand = Demand.new(demand_params.merge(project: @project))
    return render :new unless @demand.save

    redirect_to company_project_demand_path(@company, @project, @demand)
  end

  def destroy
    @demand.discard
    render 'demands/destroy.js.erb'
  end

  def edit
    respond_to { |format| format.js }
  end

  def update
    @demand.update(demand_params)
    @updated_demand = DemandsList.find(@demand.id)
    render 'demands/update'
  end

  def show
    @demand_blocks = @demand.demand_blocks.order(:block_time)
    @demand_transitions = @demand.demand_transitions.order(:last_time_in)
    @queue_percentage = Stats::StatisticsService.instance.compute_percentage(@demand.total_queue_time, @demand.total_touch_time)
    @touch_percentage = 100 - @queue_percentage
    @upstream_percentage = Stats::StatisticsService.instance.compute_percentage(@demand.working_time_upstream, @demand.working_time_downstream)
    @downstream_percentage = 100 - @upstream_percentage
  end

  def synchronize_jira
    jira_account = Jira::JiraAccount.find_by(customer_domain: @project.project_jira_config.jira_account_domain)
    Jira::ProcessJiraIssueJob.perform_later(jira_account, @project, @demand.demand_id)
    flash[:notice] = t('general.enqueued')
    redirect_to company_project_demand_path(@company, @project, @demand)
  end

  def demands_csv
    @demands_in_csv = Demand.where(id: params['demands_ids'].split(',')).kept.order(end_date: :desc)
    attributes = %w[id current_stage demand_id demand_title demand_type class_of_service effort_downstream effort_upstream created_date commitment_date end_date]
    demands_csv = CSV.generate(headers: true) do |csv|
      csv << attributes
      @demands_in_csv.each { |demand| csv << demand.csv_array }
    end
    respond_to { |format| format.csv { send_data demands_csv, filename: "demands-#{Time.zone.now}.csv" } }
  end

  def demands_in_projects
    filtered_demands = DemandsRepository.instance.demands_to_projects(@projects)
    @demands = build_demands_query(filtered_demands, 'week')
    @demands_count_per_week = DemandService.instance.quantitative_consolidation_per_week_to_projects(@projects)
    assign_consolidations

    respond_to { |format| format.js { render file: 'demands/demands_tab.js.erb' } }
  end

  def search_demands_by_flow_status
    @demands = query_demands(params[:period])
    @grouped_delivered_demands = @demands.grouped_end_date_by_month if radio_param?(:grouped_by_month)
    @grouped_customer_demands = @demands.grouped_by_customer if radio_param?(:grouped_by_customer)
    assign_consolidations

    respond_to { |format| format.js { render file: 'demands/search_demands_by_flow_status.js.erb' } }
  end

  private

  def query_demands(period)
    demands_to_projects = DemandsRepository.instance.demands_to_projects(@projects)
    build_demands_query(demands_to_projects, period)
  end

  def demand_params
    params.require(:demand).permit(:demand_id, :demand_type, :downstream, :manual_effort, :class_of_service, :assignees_count, :effort_upstream, :effort_downstream, :created_date, :commitment_date, :end_date)
  end

  def assign_project
    @project = Project.find(params[:project_id])
  end

  def assign_projects_for_queries
    @projects = Project.where(id: params[:projects_ids].split(','))
  end

  def assign_demand
    @demand = Demand.find(params[:id])
  end

  def build_demands_query(demands, period)
    filtered_demands = filter_text(demands)
    filtered_demands = filtered_demands.not_started if radio_param?(:not_started)
    filtered_demands = filtered_demands.in_wip if radio_param?(:wip)
    filtered_demands = filtered_demands.finished if radio_param?(:delivered)
    filtered_demands = filter_demand_type(filtered_demands)
    filtered_demands = filter_class_of_service(filtered_demands)

    result_query = DemandsList.where(id: filtered_demands.map(&:id))

    bottom_date = bottom_date_limit_value(period)
    result_query = result_query.where('(demands_lists.end_date IS NULL AND demands_lists.created_date >= :bottom_date) OR (demands_lists.end_date >= :bottom_date)', bottom_date: bottom_date) if bottom_date.present?

    result_query.order(end_date: :desc, commitment_date: :desc, created_date: :desc)
  end

  def filter_demand_type(demands)
    filtered_demands = demands
    filtered_demands = filtered_demands.feature if radio_param?(:feature_type)
    filtered_demands = filtered_demands.bug if radio_param?(:bug_type)
    filtered_demands = filtered_demands.chore if radio_param?(:chore_type)
    filtered_demands = filtered_demands.performance_improvement if radio_param?(:performance_improvement_type)
    filtered_demands = filtered_demands.ui if radio_param?(:ui_type)
    filtered_demands = filtered_demands.wireframe if radio_param?(:wireframe_type)
    filtered_demands
  end

  def filter_class_of_service(demands)
    filtered_demands = demands
    filtered_demands = filtered_demands.standard if radio_param?(:standard_class)
    filtered_demands = filtered_demands.expedite if radio_param?(:expedite_class)
    filtered_demands = filtered_demands.fixed_date if radio_param?(:fixed_date_class)
    filtered_demands = filtered_demands.intangible if radio_param?(:intangible_class)
    filtered_demands
  end

  def filter_text(demands)
    return demands if params[:search_text].blank?

    demands.joins(project: :product).where('demand_title ILIKE :search_param OR demand_id ILIKE :search_param OR products.name ILIKE :search_param OR projects.name ILIKE :search_param', search_param: "%#{params[:search_text].downcase}%")
  end

  def radio_param?(param)
    params[param] == 'true'
  end

  def bottom_date_limit_value(period)
    base_date = @projects.map(&:end_date).flatten.max
    base_date = Time.zone.now if @projects.blank? || @projects.map(&:status).flatten.include?('executing')
    TimeService.instance.limit_date_to_period(period, base_date)
  end

  def assign_consolidations
    @confidence_95_leadtime = Stats::StatisticsService.instance.percentile(95, @demands.map(&:leadtime_in_days))
    @confidence_80_leadtime = Stats::StatisticsService.instance.percentile(80, @demands.map(&:leadtime_in_days))
    @confidence_65_leadtime = Stats::StatisticsService.instance.percentile(65, @demands.map(&:leadtime_in_days))

    @total_queue_time = @demands.sum(&:total_queue_time)
    @total_touch_time = @demands.sum(&:total_touch_time)
  end
end
