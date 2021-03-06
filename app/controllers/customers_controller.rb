# frozen_string_literal: true

class CustomersController < AuthenticatedController
  before_action :user_gold_check
  before_action :assign_company
  before_action :assign_customer, only: %i[edit update show destroy]

  def index
    @customers = @company.customers.sort_by(&:total_flow_pressure).reverse
  end

  def show
    @customer_projects = @customer.projects.order(end_date: :desc)
    @projects_summary = ProjectsSummaryData.new(@customer.projects)
  end

  def new
    @customer = Customer.new(company: @company)
  end

  def create
    @customer = Customer.new(customer_params.merge(company: @company))
    return redirect_to company_customers_path(@company) if @customer.save

    render :new
  end

  def edit; end

  def update
    @customer.update(customer_params.merge(company: @company))
    return redirect_to company_customers_path(@company) if @customer.save

    render :edit
  end

  def destroy
    return redirect_to company_customers_path(@company) if @customer.destroy

    redirect_to(company_customers_path(@company), flash: { error: @customer.errors.full_messages.join(',') })
  end

  private

  def assign_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name)
  end
end
