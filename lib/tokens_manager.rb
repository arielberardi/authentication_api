module TokensManager
  class << self
    TOKEN_EXP_TIME = 10.minutes.to_i

    def add_to_denylist(token)
      redis_add_token(:denylist, nil, token,
                      JsonWebToken::decode(token)[:exp].to_i - Time.now.to_i)
    end

    def add_to_activationlist(account_id, token)
      redis_add_token(:activation, account_id, token)
    end

    def add_to_unlocklist(account_id, token)
      redis_add_token(:unlock, account_id, token)
    end

    def add_to_recoverylist(account_id, token)
      redis_add_token(:recovery, account_id, token)
    end

    def denied?(token)
      redis.get(denylist_key(token)) == '1'
    end

    def activation_valid?(account_id, token)
      redis.get(activation_key(account_id)) == token
    end

    def unlock_valid?(account_id, token)
      redis.get(unlock_key(account_id)) == token
    end

    def recovery_valid?(account_id, token)
      redis.get(recovery_key(account_id)) == token
    end

    private

    def activation_key(id)
      "account:#{id}:token:activation"
    end

    def unlock_key(id)
      "account:#{id}:token:unlock"
    end

    def recovery_key(id)
      "account:#{id}:token:recovery"
    end

    def denylist_key(token)
      "token:#{token}:denylist"
    end

    def redis_add_token(type, id, token, exp = TOKEN_EXP_TIME)
      return if token.nil?

      key = case type
            when :denylist then denylist_key(token)
            when :activation then activation_key(id)
            when :unlock then unlock_key(id)
            when :recovery then recovery_key(id)
            end

      redis.set(key, token)
      redis.expire(key, exp)
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
end
