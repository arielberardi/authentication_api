require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'validations' do
    # TWe need tp create an account due to an issue in 'validate_uniqueness_of'
    # https://github.com/thoughtbot/shoulda-matchers/issues/745
    before { FactoryBot.create(:account) }

    it { is_expected.to have_secure_password }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value(Faker::Internet.unique.email).for(:email) }
    
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_length_of(:first_name).is_at_least(2) }

    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_length_of(:last_name).is_at_least(2) }
  end
end
