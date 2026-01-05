class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :identities, through: :users
  has_many :insight_items, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :engagements, dependent: :destroy

  validates :name, presence: true
  validates :external_id, presence: true, uniqueness: true

  before_validation :generate_external_id, on: :create

  def to_param
    external_id
  end

  private

  def generate_external_id
    self.external_id ||= SecureRandom.uuid
  end
end
