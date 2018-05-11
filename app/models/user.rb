# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  admin                  :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           not null, indexed
#  email_notifications    :boolean          default(FALSE), not null
#  encrypted_password     :string           not null
#  first_name             :string           not null
#  id                     :integer          not null, primary key
#  last_company_id        :integer
#  last_name              :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string           indexed
#  sign_in_count          :integer          default(0), not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_971bf2d9a1  (last_company_id => companies.id)
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :companies

  validates :first_name, :last_name, :email, presence: true

  scope :to_notify_email, -> { where email_notifications: true }
end
