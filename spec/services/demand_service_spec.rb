# frozen_string_literal: true

RSpec.describe DemandService, type: :service do
  describe '#compute_effort_for_dates' do
    context 'when the dates are in the same day' do
      let(:start_date) { Time.zone.local(2018, 2, 13, 14, 0, 0) }
      let(:end_date) { Time.zone.local(2018, 2, 13, 16, 0, 0) }

      it { expect(DemandService.instance.compute_effort_for_dates(start_date, end_date)).to eq 2 }
    end
    context 'when the dates are in different days' do
      context 'and there is no weekend between the dates' do
        let(:start_date) { Time.zone.local(2018, 2, 13, 14, 0, 0) }
        let(:end_date) { Time.zone.local(2018, 2, 15, 16, 0, 0) }

        it { expect(DemandService.instance.compute_effort_for_dates(start_date, end_date)).to eq 24 }
      end
      context 'and there is weekend between the dates' do
        let(:start_date) { Time.zone.local(2018, 2, 9, 14, 0, 0) }
        let(:end_date) { Time.zone.local(2018, 2, 13, 16, 0, 0) }

        it { expect(DemandService.instance.compute_effort_for_dates(start_date, end_date)).to eq 24 }
      end
    end
    context 'when the dates are nil' do
      it { expect(DemandService.instance.compute_effort_for_dates(nil, nil)).to eq 0 }
    end
  end
end