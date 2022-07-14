require 'jwt'

module JsonWebToken
  class << self
    SECRET_KEY = Rails.application.credentials.jwt_key_base

    def encode(payload)
      payload[:exp] = 30.minutes.from_now.to_i
      JWT.encode(payload, SECRET_KEY)
    end

    def decode(token)
      return if token.nil?

      decoded = JWT.decode(token, SECRET_KEY).first
      HashWithIndifferentAccess.new(decoded)
    end
  end
end
