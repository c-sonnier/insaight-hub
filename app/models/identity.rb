class Identity < ApplicationRecord
  has_secure_password
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end
  generates_token_for :account_setup, expires_in: 7.days do
    password_salt&.last(10)
  end

  has_many :sessions, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :accounts, through: :users
  has_one_attached :avatar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :api_token, uniqueness: true, allow_nil: true
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true

  before_create :generate_api_token

  def regenerate_api_token!
    update!(api_token: SecureRandom.hex(32))
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
