class AccountsMailer < ApplicationMailer
  def activation(account, token)
    @account = account
    @token = token

    mail to: @account.email, subject: 'Account activation'
  end

  def unlock(account, token)
    @account = account
    @token = token

    mail to: @account.email, subject: 'Account locked'
  end

  def reset_password(account, token)
    @account = account
    @token = token

    mail to: @account.email, subject: 'Request to reset password'
  end
end
