require 'rails_helper'

shared_examples 'account is not from the user' do
  let(:other_account) { create(:account) }

  subject do
    get account_url(other_account), headers: valid_headers, as: :json
    response
  end

  it { is_expected.to have_http_status(:unauthorized) }
end

shared_examples 'user is not logged in' do
  let(:valid_headers) { {} }

  it { is_expected.to have_http_status(:unauthorized) }
end

RSpec.describe AccountsController, type: :request do
  let(:valid_attributes) { attributes_for(:account) }
  let(:invalid_attributes) { attributes_for(:account, last_name: '') }

  let(:account) { Account.create!(valid_attributes) }
  let(:account_filtered) do
    {
      email: account.email,
      first_name: account.first_name,
      last_name: account.last_name,
      created_at: account.created_at.strftime('%Y-%m-%d')
    }.to_json
  end

  let(:valid_headers) do
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{get_token(account)}"
    }
  end

  describe 'GET /show' do
    subject do
      get account_url(account), headers: valid_headers, as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.body).to eq(account_filtered) }

    context 'when account does not exists' do
      before { account.destroy }

      it { is_expected.to have_http_status(:not_found) }
    end

    it_behaves_like 'account is not from the user'
    it_behaves_like 'user is not logged in'
  end

  describe 'POST /create' do
    let(:account) { Account.last }
    let(:mail_double) { double }

    before { allow(mail_double).to receive(:deliver_later) }

    subject do
      post accounts_url, params: { account: valid_attributes }, as: :json
      response
    end

    it { is_expected.to have_http_status(:created) }
    it { expect { subject }.to change(Account, :count).by(1) }
    it { expect(subject.content_type).to match(a_string_including('application/json')) }
    it { expect(subject.body).to eq(account_filtered) }

    it 'creates a new activation token' do
      expect(TokensManager).to receive(:add_to_activationlist)
      subject
    end

    it 'email includes activation token' do
      expect(AccountsMailer).to receive(:activation).and_return(mail_double)
      subject
    end

    context 'with invalid parameters' do
      let(:valid_attributes) { invalid_attributes }

      it { is_expected.to have_http_status(:unprocessable_entity) }
      it { expect { subject }.to change(Account, :count).by(0) }
      it { expect(subject.content_type).to match(a_string_including('application/json')) }
      it { expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(0) }
    end
  end

  describe 'GET /activate' do
    let(:account) { FactoryBot.create(:account, activated: false) }
    let(:token) { 'TOKEN' }

    before { TokensManager::add_to_activationlist(account.id, token) }

    subject do
      get activate_account_url(account.id, token), as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.content_type).to match(a_string_including('application/json')) }
    it { expect(subject.body).to eq({ message: 'Account activated' }.to_json) }

    it 'activates account' do
      subject
      expect(Account.last.activated?).to be true
    end

    context 'when token is invalid' do
      before { TokensManager::add_to_activationlist(account.id, 'invalid_token') }

      it { is_expected.to have_http_status(:unprocessable_entity) }
      it { expect(subject.content_type).to match(a_string_including('application/json')) }
      it { expect(subject.body).to eq({ error: 'Invalid token' }.to_json) }

      it 'does not activate the account' do
        subject
        expect(Account.find(account.id).activated?).to be false
      end
    end
  end

  describe 'PUT /update' do
    let(:new_attributes) { attributes_for(:account, email: account.email) }
    let(:account_filtered) do
      {
        email: account.email,
        first_name: new_attributes[:first_name],
        last_name: new_attributes[:last_name],
        created_at: account.created_at.strftime('%Y-%m-%d')
      }.to_json
    end

    subject do
      put account_url(account),
          params: { account: new_attributes }, headers: valid_headers, as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.content_type).to match(a_string_including('application/json')) }
    it { expect(subject.body).to eq(account_filtered) }

    context 'with invalid parameters' do
      let(:new_attributes) { invalid_attributes }

      it { is_expected.to have_http_status(:unprocessable_entity) }
      it { expect(subject.content_type).to match(a_string_including('application/json')) }
    end

    it_behaves_like 'account is not from the user'
    it_behaves_like 'user is not logged in'
  end

  describe 'PATCH /reset_password' do
    let(:new_attributes) do
      {
        password: 'new_password',
        password_confirmation: 'new_password'
      }
    end

    let(:token) { 'token' }

    before { TokensManager::add_to_recoverylist(account.id, token) }

    subject do
      patch reset_password_account_url(account.id, token),
            params: { account: new_attributes }, as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.content_type).to match(a_string_including('application/json')) }
    it { expect(subject.body).to eq({ message: 'Account updated' }.to_json) }
    it { expect { subject }.to change { Account.last.password_digest } }

    context 'when attributes are invalid' do
      let(:new_attributes) do
        {
          password: 'my_new_password',
          password_confirmation: ''
        }
      end

      it { is_expected.to have_http_status(:unprocessable_entity) }
      it { expect(subject.content_type).to match(a_string_including('application/json')) }
    end

    context 'when token is invalid' do
      before { TokensManager::add_to_recoverylist(account.id, 'other_token') }

      it { is_expected.to have_http_status(:unprocessable_entity) }
      it { expect(subject.body).to eq({ error: 'Invalid token' }.to_json) }
    end
  end

  describe 'GET /unlock' do
    let(:account) { FactoryBot.create(:account, locked: true) }
    let(:token) { 'TOKEN' }

    before { TokensManager::add_to_unlocklist(account.id, token) }

    subject do
      get unlock_account_url(account.id, token), as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.content_type).to match(a_string_including('application/json')) }
    it { expect(subject.body).to eq({ message: 'Account unlocked' }.to_json) }

    it 'unlocks the account' do
      subject
      expect(Account.find(account.id).locked?).to be false
    end

    context 'when token is invalid' do
      before { TokensManager::add_to_unlocklist(account.id, 'invalid_token') }

      it { is_expected.to have_http_status(:unprocessable_entity) }
      it { expect(subject.content_type).to match(a_string_including('application/json')) }
      it { expect(subject.body).to eq({ error: 'Invalid token' }.to_json) }

      it 'does not unlock the account' do
        subject
        expect(Account.find(account.id).locked?).to be true
      end
    end
  end

  describe 'DELETE /destroy' do
    before { account }

    subject do
      delete account_url(account), headers: valid_headers, as: :json
      response
    end

    it { is_expected.to have_http_status(:no_content) }
    it { expect { subject }.to change(Account, :count).by(-1) }

    it_behaves_like 'account is not from the user'
    it_behaves_like 'user is not logged in'
  end
end
