# frozen_string_literal: true

RSpec.describe FlowReportData, type: :data_object do
  context 'having projects' do
    let(:first_project) { Fabricate :project, status: :executing, start_date: 2.weeks.ago, end_date: 1.week.from_now }
    let(:second_project) { Fabricate :project, status: :waiting, start_date: 1.week.from_now, end_date: 2.weeks.from_now }
    let(:third_project) { Fabricate :project, status: :maintenance, start_date: 2.weeks.from_now, end_date: 3.weeks.from_now }

    let!(:first_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago }
    let!(:second_demand) { Fabricate :demand, project: first_project, end_date: 1.week.ago }
    let!(:third_demand) { Fabricate :demand, project: second_project, end_date: 1.week.ago }
    let!(:fourth_demand) { Fabricate :demand, project: second_project, end_date: 1.week.ago }
    let!(:fifth_demand) { Fabricate :demand, project: third_project, end_date: 1.week.ago }

    let!(:sixth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago }
    let!(:seventh_demand) { Fabricate :demand, project: second_project, commitment_date: 1.week.ago }
    let!(:eigth_demand) { Fabricate :demand, project: first_project, commitment_date: 1.week.ago }
    let!(:nineth_demand) { Fabricate :demand, project: second_project, commitment_date: 1.week.ago }
    let!(:tenth_demand) { Fabricate :demand, project: third_project, commitment_date: 1.week.ago }

    let!(:out_date_processed_demand) { Fabricate :demand, project: third_project, end_date: 2.weeks.ago }
    let!(:out_date_selected_demand) { Fabricate :demand, project: third_project, commitment_date: 2.weeks.ago }

    describe '.initialize' do
      let(:selected_demands) { DemandsRepository.instance.selected_grouped_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }
      let(:processed_demands) { DemandsRepository.instance.throughput_grouped_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }

      it 'extracts the information of flow' do
        flow_data = FlowReportData.new(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear)
        expect(flow_data.projects_in_chart).to match_array [first_project, second_project, third_project]
        expect(flow_data.total_arrived).to eq [2, 2, 1]
        expect(flow_data.total_processed).to eq [2, 2, 1]

        expect(flow_data.projects_demands_selected[first_project]).to match_array [sixth_demand, eigth_demand]
        expect(flow_data.projects_demands_selected[second_project]).to match_array [seventh_demand, nineth_demand]
        expect(flow_data.projects_demands_selected[third_project]).to match_array [tenth_demand]

        expect(flow_data.projects_demands_processed[first_project]).to match_array [first_demand, second_demand]
        expect(flow_data.projects_demands_processed[second_project]).to match_array [third_demand, fourth_demand]
        expect(flow_data.projects_demands_processed[third_project]).to match_array [fifth_demand]

        expect(flow_data.processing_rate_data[first_project]).to match_array [first_demand, second_demand, sixth_demand, eigth_demand]
        expect(flow_data.processing_rate_data[second_project]).to match_array [third_demand, fourth_demand, seventh_demand, nineth_demand]
        expect(flow_data.processing_rate_data[third_project]).to match_array [fifth_demand, tenth_demand]

        expect(flow_data.column_chart_data).to eq([{ name: I18n.t('demands.charts.processing_rate.arrived'), data: [2, 2, 1] }, { name: I18n.t('demands.charts.processing_rate.processed'), data: [2, 2, 1] }])
      end
    end
  end
  context 'having no projects' do
    describe '.initialize' do
      let(:selected_demands) { DemandsRepository.instance.selected_grouped_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }
      let(:processed_demands) { DemandsRepository.instance.throughput_grouped_by_project_and_week(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear).group_by(&:project) }
      subject(:flow_data) { FlowReportData.new(Project.all, 1.week.ago.to_date.cweek, 1.week.ago.to_date.cwyear) }

      it 'extracts the information of flow' do
        expect(flow_data.projects_in_chart).to eq []
        expect(flow_data.total_arrived).to eq []
        expect(flow_data.total_processed).to eq []

        expect(flow_data.projects_demands_selected).to eq({})
        expect(flow_data.projects_demands_processed).to eq({})
        expect(flow_data.processing_rate_data).to eq({})

        expect(flow_data.column_chart_data).to eq([{ name: I18n.t('demands.charts.processing_rate.arrived'), data: [] }, { name: I18n.t('demands.charts.processing_rate.processed'), data: [] }])
      end
    end
  end
end
