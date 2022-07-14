FactoryBot.define do
  factory :account do
    email { Faker::Internet.unique.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { Faker::Internet.password(min_length: 8) }
    password_confirmation { password }
    activated { true }
    locked { false }
  end
end
