class SessionsController < ApplicationController
  before_action :authenticate_user!, only: %i[sign_out]

  def sign_in
    case sign_in_account(account_params)
    when :ok
      response.headers['Authorization'] = "Bearer #{@token}"
      render json: { message: 'Signed in' }
    when :forbidden
      render json: { error: 'Account inactive' }, status: :forbidden
    when :locked
      render json: { error: 'Account locked' }, status: :locked
    else
      if validate_attemps
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      else
        render json: { error: 'Account locked' }, status: :locked
      end
    end
  end

  def sign_out
    TokensManager::add_to_denylist(request.headers['Authorization']&.split&.last)

    render json: { message: 'Signed out' }, status: :ok
  end

  def forgot_password
    @account = Account.find_by(email: account_params[:email])

    if @account
      send_recover_password_email
      render json: { message: 'Email sent' }
    else
      render json: { error: 'Invalid email' }, status: :not_found
    end
  end

  private

  def account_params
    params.require(:account).permit(:email, :password)
  end

  def validate_attemps
    return true if @account.nil?

    redis.set(attemps_key(@account.id), redis.get(attemps_key(@account.id)).to_i + 1)
    redis.expire(attemps_key(@account.id), 12.hours.to_i)

    if redis.get(attemps_key(@account.id)).to_i >= 3
      send_unlock_email
      @account.update(locked: true)
      return false
    end

    true
  end

  def send_unlock_email
    token = Account.generate_unique_secure_token

    TokensManager::add_to_unlocklist(@account.id, token)

    AccountsMailer.unlock(@account, token).deliver_later
  end

  def send_recover_password_email
    token = Account.generate_unique_secure_token

    TokensManager::add_to_recoverylist(@account.id, token)

    AccountsMailer.reset_password(@account, token).deliver_later
  end

  def attemps_key(account_id)
    "account:#{account_id}:attemps"
  end

  def redis
    @redis ||= Redis.new(host: redis_config[:host],
                         port: redis_config[:port],
                         db: redis_config[:database])
  end

  def redis_config
    @redis_config ||= YAML.load_file('config/redis.yml')['redis'].symbolize_keys
  end
end
