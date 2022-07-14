module Authentication
  def sign_in_account(account_params)
    @account = Account.find_by(email: account_params[:email])

    return :unauthorized if @account.nil?
    return :unauthorized unless @account.authenticate(account_params[:password])
    return :forbidden unless @account.activated?
    return :locked if @account.locked?

    @token = JsonWebToken::encode({ account_id: @account.id })

    :ok
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split&.last
    raise(StandardError, 'Missing token') if token.blank?
    raise(StandardError, 'Invalid token') if TokensManager::denied?(token)

    decoded = JsonWebToken::decode(token)
    @current_account = Account.find(decoded[:account_id])
  rescue JWT::ExpiredSignature
    render json: { error: 'Token has expired' }, status: :unauthorized
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid account' }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unauthorized
  end

  def verify_ownership!
    return if @current_account && @current_account.id == params[:id].to_i

    render json: { error: 'Invalid rights' }, status: :unauthorized
  end
end
