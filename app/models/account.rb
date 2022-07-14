class Account < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }
  validates :first_name, presence: true, length: { minimum: 2 }
  validates :last_name, presence: true, length: { minimum: 2 }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_digest_changed?

  def filtered
    {
      email: email,
      first_name: first_name,
      last_name: last_name,
      created_at: created_at.strftime('%Y-%m-%d')
    }
  end
end
