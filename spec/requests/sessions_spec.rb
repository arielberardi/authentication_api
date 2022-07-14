require 'rails_helper'

RSpec.describe SessionsController, type: :request do
  let(:account) { FactoryBot.create(:account) }
  let(:credentials) do
    {
      email: account.email,
      password: account.password
    }
  end

  before { account }

  describe 'POST /sign_in' do
    let(:redis) { Redis.new }
    let(:attemps_key) { "account:#{account.id}:attemps" }

    before { redis }

    subject do
      post sign_in_url, params: { account: credentials }, as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.body).to eq({ message: 'Signed in' }.to_json) }
    it { expect(subject.headers['Authorization']).to_not be nil }
    it { expect(extract_account_id(subject.headers)).to eq(account.id) }
    it { expect(account.locked?).to be false }

    it 'sets attemps count to cero' do
      subject
      expect(redis.get(attemps_key).to_i).to eq(0)
    end

    context 'when account is not activated' do
      let(:account) { FactoryBot.create(:account, activated: false) }

      it { is_expected.to have_http_status(:forbidden) }
      it { expect(subject.body).to eq({ error: 'Account inactive' }.to_json) }
      it { expect(subject.headers['Authorization']).to be nil }
    end

    context 'with invalid credentials' do
      let(:credentials) do
        {
          email: account.email,
          passsword: 'wrong_password'
        }
      end

      it { is_expected.to have_http_status(:unauthorized) }
      it { expect(subject.body).to eq({ error: 'Invalid email or password' }.to_json) }
      it { expect(subject.headers['Authorization']).to be nil }
      it { expect { subject }.to change { redis.get(attemps_key).to_i }.by(1) }

      context 'and attemps count is more than 3' do
        let(:mail_double) { double }

        before do
          allow(mail_double).to receive(:deliver_later)
          redis.set(attemps_key, 3)
        end

        it { is_expected.to have_http_status(:locked) }
        it { expect(subject.body).to eq({ error: 'Account locked' }.to_json) }
        it { expect(subject.headers['Authorization']).to be nil }

        it 'sends email to unlock account' do
          expect(AccountsMailer).to receive(:unlock).and_return(mail_double)
          subject
        end

        it 'locks the account' do
          subject
          expect(Account.last.locked?).to be true
        end
      end
    end
  end

  describe 'DELETE /sign_out' do
    let(:token) { get_token(account) }
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
    end

    let(:redis) { Redis.new }

    subject do
      delete sign_out_url, headers: headers, as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.body).to eq({ message: 'Signed out' }.to_json) }

    it 'adds token to denylist' do
      expect(TokensManager).to receive(:add_to_denylist)
      subject
    end

    context 'when user is not signed in' do
      let(:headers) { {} }

      it { is_expected.to have_http_status(:unauthorized) }
    end
  end

  describe 'POST /forgot_password' do
    let(:credentials) { { email: account.email } }
    let(:mail_double) { double }

    before { allow(mail_double).to receive(:deliver_later) }

    subject do
      post forgot_password_url, params: { account: credentials }, as: :json
      response
    end

    it { is_expected.to have_http_status(:success) }
    it { expect(subject.body).to eq({ message: 'Email sent' }.to_json) }

    it 'sends email to account' do
      expect(AccountsMailer).to receive(:reset_password).and_return(mail_double)
      subject
    end

    it 'generates a token in recovery list' do
      expect(TokensManager).to receive(:add_to_recoverylist)
      subject
    end
  end
end
