class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :component_requests, dependent: :destroy

  before_create :generate_api_key

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end
