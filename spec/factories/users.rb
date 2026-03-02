FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    name { Faker::Name.name }
    api_key { SecureRandom.hex(32) }
  end
end
