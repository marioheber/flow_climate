# frozen_string_literal: true

# == Schema Information
#
# Table name: team_members
#
#  active                :boolean          default(TRUE)
#  billable              :boolean          default(TRUE)
#  billable_type         :integer          default("outsourcing")
#  created_at            :datetime         not null
#  hour_value            :decimal(, )      default(0.0)
#  hours_per_month       :integer          not null
#  id                    :bigint(8)        not null, primary key
#  monthly_payment       :decimal(, )      not null
#  name                  :string           not null
#  team_id               :integer          not null
#  total_monthly_payment :decimal(, )      not null
#  updated_at            :datetime         not null
#
# Foreign Keys
#
#  fk_rails_194b5b076d  (team_id => teams.id)
#

class TeamMember < ApplicationRecord
  enum billable_type: { outsourcing: 0, consulting: 1, training: 2, domestic_product: 3 }

  belongs_to :team

  validates :team, :name, :monthly_payment, :hours_per_month, presence: true

  scope :active, -> { where active: true }
end
