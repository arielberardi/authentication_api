module AuthenticationHelpers
  def get_token(account)
    JsonWebToken::encode({ account_id: account.id })
  end

  def extract_account_id(header)
    token = header['Authorization']&.split&.last
    return if token.blank?

    JsonWebToken::decode(token)[:account_id]
  end
end
