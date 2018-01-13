# frozen_string_literal: true

RSpec.describe Project, type: :model do
  context 'enums' do
    it { is_expected.to define_enum_for(:status).with(waiting: 0, executing: 1, finished: 2, cancelled: 3) }
    it { is_expected.to define_enum_for(:project_type).with(outsourcing: 0, consulting: 1, training: 2) }
  end

  context 'associations' do
    it { is_expected.to belong_to :customer }
    it { is_expected.to have_many :project_results }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :start_date }
    it { is_expected.to validate_presence_of :end_date }
    it { is_expected.to validate_presence_of :status }
    it { is_expected.to validate_presence_of :initial_scope }
  end

  context 'delegations' do
    it { is_expected.to delegate_method(:name).to(:customer).with_prefix }
  end

  describe '#total_days' do
    let(:project) { Fabricate :project, start_date: 1.day.ago, end_date: 1.day.from_now }
    it { expect(project.total_days).to eq 2 }
  end

  describe '#remaining_days' do
    context 'when the end date is in the future' do
      let(:project) { Fabricate :project, start_date: 1.day.ago, end_date: 1.day.from_now }
      it { expect(project.remaining_days).to eq 1 }
    end
    context 'when the end date is in the past' do
      let(:project) { Fabricate :project, start_date: 2.days.ago, end_date: 1.day.ago }
      it { expect(project.remaining_days).to eq 0 }
    end
    context 'when the start date is in the future' do
      let(:project) { Fabricate :project, start_date: 2.days.from_now, end_date: 3.days.from_now }
      it { expect(project.remaining_days).to eq 0 }
    end
  end

  describe '#consumed_hours' do
    let(:project) { Fabricate :project }
    let!(:result) { Fabricate :project_result, project: project }
    let!(:other_result) { Fabricate :project_result, project: project }
    it { expect(project.consumed_hours).to eq result.total_hours_consumed + other_result.total_hours_consumed }
  end

  describe '#remaining_money' do
    let(:project) { Fabricate :project, qty_hours: 1000, value: 100_000, hour_value: 100 }
    let!(:result) { Fabricate :project_result, project: project, qty_hours_downstream: 10 }
    let!(:other_result) { Fabricate :project_result, project: project, qty_hours_downstream: 20 }
    it { expect(project.remaining_money.to_f).to eq 97_000 }
  end

  describe '#red?' do
    context 'when it is executing' do
      let(:project) { Fabricate :project, status: :executing, qty_hours: 1000, value: 100_000, hour_value: 100, start_date: 1.day.ago, end_date: 1.month.from_now }
      context 'when there is less money than time remaining' do
        let!(:result) { Fabricate :project_result, project: project, qty_hours_downstream: 400 }
        let!(:other_result) { Fabricate :project_result, project: project, qty_hours_downstream: 300 }
        it { expect(project.red?).to be true }
      end
      context 'when there is more money than time remaining' do
        let!(:result) { Fabricate :project_result, project: project, qty_hours_downstream: 1 }
        let!(:other_result) { Fabricate :project_result, project: project, qty_hours_downstream: 2 }
        it { expect(project.red?).to be false }
      end
    end
    context 'when it is waiting' do
      let(:project) { Fabricate :project, status: :waiting, qty_hours: 1000, value: 100_000, hour_value: 100, start_date: 1.day.ago, end_date: 1.month.from_now }
      context 'when there is less money than time remaining' do
        let!(:result) { Fabricate :project_result, project: project, qty_hours_downstream: 400 }
        let!(:other_result) { Fabricate :project_result, project: project, qty_hours_downstream: 300 }
        it { expect(project.red?).to be false }
      end
    end
    context 'when it is finished' do
      let(:project) { Fabricate :project, status: :finished, qty_hours: 1000, value: 100_000, hour_value: 100, start_date: 1.day.ago, end_date: 1.month.from_now }
      context 'when there is less money than time remaining' do
        let!(:result) { Fabricate :project_result, project: project, qty_hours_downstream: 400 }
        let!(:other_result) { Fabricate :project_result, project: project, qty_hours_downstream: 300 }
        it { expect(project.red?).to be false }
      end
    end
    context 'when it is cancelled' do
      let(:project) { Fabricate :project, status: :cancelled, qty_hours: 1000, value: 100_000, hour_value: 100, start_date: 1.day.ago, end_date: 1.month.from_now }
      context 'when there is less money than time remaining' do
        let!(:result) { Fabricate :project_result, project: project, qty_hours_downstream: 400 }
        let!(:other_result) { Fabricate :project_result, project: project, qty_hours_downstream: 300 }
        it { expect(project.red?).to be false }
      end
    end
  end
end