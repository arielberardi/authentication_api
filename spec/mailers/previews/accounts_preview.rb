# Preview all emails at http://localhost:3000/rails/mailers/accounts
class AccountsPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/accounts/activation
  def activation
    AccountsMailer.activation
  end

end
