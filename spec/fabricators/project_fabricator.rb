# frozen_string_literal: true

Fabricator(:project) do
  customer
  product { |attrs| Fabricate :product, customer: attrs[:customer] }
  name { Faker::Name.unique.name }
  start_date 2.months.ago
  end_date 2.months.from_now
  status 0
  project_type 0
  initial_scope 30
  value { Faker::Number.decimal }
  qty_hours { Faker::Number.number(3) }
  hour_value { Faker::Number.decimal(2) }
end
