# frozen_string_literal: true

RSpec.describe Highchart::DemandsChartsAdapter, type: :data_object do
  before { travel_to Time.zone.local(2018, 9, 3, 12, 20, 31) }
  after { travel_back }

  context 'having demands' do
    let(:company) { Fabricate :company }
    let(:customer) { Fabricate :customer, company: company }

    let(:first_project) { Fabricate :project, customer: customer, status: :executing, start_date: 4.months.ago, end_date: 1.week.from_now }
    let(:second_project) { Fabricate :project, customer: customer, status: :waiting, start_date: 5.months.ago, end_date: 2.weeks.from_now }
    let(:third_project) { Fabricate :project, customer: customer, status: :maintenance, start_date: 3.months.ago, end_date: 3.weeks.from_now }

    let!(:first_demand) { Fabricate :demand, project: first_project, commitment_date: 4.months.ago, end_date: 3.months.ago, effort_downstream: 16, effort_upstream: 123 }
    let!(:second_demand) { Fabricate :demand, project: second_project, commitment_date: 5.months.ago, end_date: 3.months.ago, effort_downstream: 7, effort_upstream: 221 }
    let!(:third_demand) { Fabricate :demand, project: first_project, commitment_date: 3.months.ago, end_date: 2.months.ago, effort_downstream: 11, effort_upstream: 76 }
    let!(:fourth_demand) { Fabricate :demand, project: second_project, commitment_date: 2.months.ago, end_date: 1.month.ago, effort_downstream: 32, effort_upstream: 332 }
    let!(:fifth_demand) { Fabricate :demand, project: third_project, commitment_date: 2.months.ago, end_date: Time.zone.today, effort_downstream: 76, effort_upstream: 12 }

    describe '#throughput_chart_data' do
      it 'computes and extracts the information of finances' do
        throughput_chart_data = Highchart::DemandsChartsAdapter.new(Demand.all, 'week').throughput_chart_data

        expect(throughput_chart_data[:x_axis]).to eq TimeService.instance.weeks_between_of(Date.new(2018, 5, 28), Date.new(2018, 9, 3))
        expect(throughput_chart_data[:y_axis][0][:name]).to eq I18n.t('general.throughput')
        expect(throughput_chart_data[:y_axis][0][:data]).to eq [2, 1, 1, 1]
      end
    end
  end
  context 'having no demands' do
    describe '.initialize' do
      subject(:throughput_chart_data) { Highchart::DemandsChartsAdapter.new(Demand.all, 'week').throughput_chart_data }
      it 'returns empty information' do
        expect(throughput_chart_data[:x_axis]).to eq [Time.zone.today]
        expect(throughput_chart_data[:y_axis][0][:name]).to eq I18n.t('general.throughput')
        expect(throughput_chart_data[:y_axis][0][:data]).to eq []
      end
    end
  end
end
