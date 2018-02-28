# frozen_string_literal: true

Fabricator(:stage) do
  integration_id { Faker::IDNumber.valid }
  name { Faker::Name.name }
  stage_type { [0, 1, 2, 3, 4, 5, 6].sample }
  stage_stream { [0, 1].sample }
end