# frozen_string_literal: true

RSpec.describe Highchart::FlowChartsAdapter, type: :data_object do
  context 'having projects' do
    before { travel_to Time.zone.local(2018, 4, 6, 10, 0, 0) }
    after { travel_back }

    let(:first_project) { Fabricate :project, status: :executing, start_date: 2.weeks.ago, end_date: 1.week.from_now, qty_hours: 100 }
    let(:second_project) { Fabricate :project, status: :waiting, start_date: 1.week.from_now, end_date: 2.weeks.from_now, qty_hours: 200 }
    let(:third_project) { Fabricate :project, status: :maintenance, start_date: 2.weeks.from_now, end_date: 3.weeks.from_now, qty_hours: 300 }

    let!(:first_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago, downstream: false, effort_downstream: 111, effort_upstream: 1000 }
    let!(:second_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago, effort_downstream: 120, effort_upstream: 12 }
    let!(:third_demand) { Fabricate :demand, project: second_project, end_date: 1.week.ago, effort_downstream: 20, effort_upstream: 111 }
    let!(:fourth_demand) { Fabricate :demand, project: second_project, end_date: 1.week.ago, effort_downstream: 60, effort_upstream: 155 }
    let!(:fifth_demand) { Fabricate :demand, project: third_project, end_date: 1.week.ago, effort_downstream: 12, effort_upstream: 107 }

    let!(:sixth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago, effort_downstream: 16, effort_upstream: 123 }
    let!(:seventh_demand) { Fabricate :demand, project: second_project, commitment_date: 1.week.ago, effort_downstream: 7, effort_upstream: 221 }
    let!(:eigth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago, effort_downstream: 11, effort_upstream: 76 }
    let!(:nineth_demand) { Fabricate :demand, project: second_project, commitment_date: 1.week.ago, effort_downstream: 32, effort_upstream: 332 }
    let!(:tenth_demand) { Fabricate :demand, project: third_project, commitment_date: 1.week.ago, effort_downstream: 76, effort_upstream: 12 }

    let!(:out_date_processed_demand) { Fabricate :demand, project: third_project, end_date: Time.zone.today, effort_downstream: 32, effort_upstream: 332 }
    let!(:out_date_selected_demand) { Fabricate :demand, project: third_project, commitment_date: 2.months.ago, effort_downstream: 7, effort_upstream: 221 }

    describe '.initialize' do
      let(:selected_demands) { DemandsRepository.instance.committed_demands_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }
      let(:processed_demands) { DemandsRepository.instance.throughput_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }

      it 'extracts the information of flow' do
        flow_data = Highchart::FlowChartsAdapter.new(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)
        expect(flow_data.projects_in_chart).to match_array [first_project, second_project, third_project]
        expect(flow_data.total_arrived).to match_array [2, 2, 1]
        expect(flow_data.total_processed_upstream).to match_array [1, 0, 0]
        expect(flow_data.total_processed_downstream).to match_array [1, 2, 1]

        expect(flow_data.projects_demands_selected[first_project]).to match_array [sixth_demand, eigth_demand]
        expect(flow_data.projects_demands_selected[second_project]).to match_array [seventh_demand, nineth_demand]
        expect(flow_data.projects_demands_selected[third_project]).to match_array [tenth_demand]

        expect(flow_data.projects_demands_processed[first_project]).to match_array [first_demand, second_demand]
        expect(flow_data.projects_demands_processed[second_project]).to match_array [third_demand, fourth_demand]
        expect(flow_data.projects_demands_processed[third_project]).to match_array [fifth_demand]

        expect(flow_data.processing_rate_data[first_project]).to match_array [first_demand, second_demand, sixth_demand, eigth_demand]
        expect(flow_data.processing_rate_data[second_project]).to match_array [third_demand, fourth_demand, seventh_demand, nineth_demand]
        expect(flow_data.processing_rate_data[third_project]).to match_array [fifth_demand, tenth_demand]

        expect(flow_data.wip_per_day[0][:data]).to eq [1, 1, 1, 1, 6, 6, 6]
        expect(flow_data.demands_in_wip[Date.new(2018, 3, 26).to_s]).to eq [out_date_selected_demand]
        expect(flow_data.demands_in_wip[Date.new(2018, 3, 27).to_s]).to eq [out_date_selected_demand]
        expect(flow_data.demands_in_wip[Date.new(2018, 3, 28).to_s]).to eq [out_date_selected_demand]
        expect(flow_data.demands_in_wip[Date.new(2018, 3, 29).to_s]).to eq [out_date_selected_demand]
        expect(flow_data.demands_in_wip[Date.new(2018, 3, 30).to_s]).to match_array [out_date_selected_demand, sixth_demand, seventh_demand, eigth_demand, nineth_demand, tenth_demand]
        expect(flow_data.demands_in_wip[Date.new(2018, 3, 31).to_s]).to match_array [out_date_selected_demand, sixth_demand, seventh_demand, eigth_demand, nineth_demand, tenth_demand]
        expect(flow_data.demands_in_wip[Date.new(2018, 4, 1).to_s]).to match_array [out_date_selected_demand, sixth_demand, seventh_demand, eigth_demand, nineth_demand, tenth_demand]

        expect(flow_data.column_chart_data).to match_array([{ name: 'Total Entrada', data: [2, 2, 1], stack: 0, yaxis: 0 }, { name: 'Processadas no Downstream', data: [1, 2, 1], stack: 1, yaxis: 1 }, { name: 'Processadas no Upstream', data: [1, 0, 0], stack: 1, yaxis: 1 }])

        expect(flow_data.x_axis_month_data).to eq [[2018.0, 3.0], [2018.0, 4.0]]
        expect(flow_data.hours_per_project_per_month).to eq [1708.0, 1498.0]
      end
    end
  end
  context 'having no projects' do
    describe '.initialize' do
      let(:selected_demands) { DemandsRepository.instance.committed_demands_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }
      let(:processed_demands) { DemandsRepository.instance.throughput_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }
      subject(:flow_data) { Highchart::FlowChartsAdapter.new(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear) }

      it 'returns an empty set' do
        expect(flow_data.projects_in_chart).to eq []
        expect(flow_data.total_arrived).to eq []
        expect(flow_data.total_processed_upstream).to eq []
        expect(flow_data.total_processed_downstream).to eq []

        expect(flow_data.projects_demands_selected).to eq({})
        expect(flow_data.projects_demands_processed).to eq({})
        expect(flow_data.processing_rate_data).to eq({})

        expect(flow_data.column_chart_data).to eq([{ name: I18n.t('demands.charts.processing_rate.arrived'), data: [], stack: 0, yaxis: 0 }, { name: I18n.t('demands.charts.processing_rate.processed_downstream'), data: [], stack: 1, yaxis: 1 }, { name: I18n.t('demands.charts.processing_rate.processed_upstream'), data: [], stack: 1, yaxis: 1 }])
      end
    end
  end
end
