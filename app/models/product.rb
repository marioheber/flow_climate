# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id          :integer          not null, primary key
#  customer_id :integer          not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_products_on_customer_id  (customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

class Product < ApplicationRecord
  belongs_to :customer
  has_many :projects, dependent: :restrict_with_error

  validates :name, :customer, presence: true

  delegate :count, to: :projects, prefix: true

  def active_projects
    projects.executing
  end

  def waiting_projects
    projects.waiting
  end

  def red_projects
    projects.select(&:red?)
  end

  def current_backlog
    projects.sum(&:current_backlog)
  end

  delegate :name, to: :customer, prefix: true
end