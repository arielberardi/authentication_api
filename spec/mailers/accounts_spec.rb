require 'rails_helper'

RSpec.describe AccountsMailer, type: :mailer do
  describe 'activation' do
    let(:account) { FactoryBot.create(:account) }
    let(:token) { Account.generate_unique_secure_token }
    subject { AccountsMailer.activation(account, token) }

    it 'renders the headers' do
      expect(subject.subject).to eq('Account activation')
      expect(subject.to).to eq([account.email])
      expect(subject.from).to eq([Rails.application.credentials.email[:username]])
    end

    it 'renders the body' do
      expect(subject.body.encoded).to include(activate_account_url(account.id, token))
    end
  end

  describe 'unlock' do
    let(:account) { FactoryBot.create(:account) }
    let(:token) { Account.generate_unique_secure_token }

    subject { AccountsMailer.unlock(account, token) }

    it 'renders the headers' do
      expect(subject.subject).to eq('Account locked')
      expect(subject.to).to eq([account.email])
      expect(subject.from).to eq([Rails.application.credentials.email[:username]])
    end

    it 'renders the body' do
      expect(subject.body.encoded).to include(unlock_account_url(account.id, token))
    end
  end

  describe 'reset_password' do
    let(:account) { FactoryBot.create(:account) }
    let(:token) { Account.generate_unique_secure_token }

    subject { AccountsMailer.reset_password(account, token) }

    it 'renders the headers' do
      expect(subject.subject).to eq('Request to reset password')
      expect(subject.to).to eq([account.email])
      expect(subject.from).to eq([Rails.application.credentials.email[:username]])
    end

    it 'renders the body' do
      expect(subject.body.encoded).to include(reset_password_account_url(account.id, token))
    end
  end
end
