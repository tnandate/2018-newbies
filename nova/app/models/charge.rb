# frozen_string_literal: true

class Charge < ApplicationRecord
  belongs_to :user

  validates_inclusion_of :amount, in: [100, 500, 1000, 5000]

  before_create :create_stripe_charge

  protected

  def create_stripe_charge
    Stripe::Charge.create(
      amount: amount,
      currency: 'jpy',
      customer: user.stripe_id
    )
  rescue Stripe::StripeError => e
    Rails.logger.error("code: " + e.code.to_s)
    Rails.logger.error("http_status: " + e.http_status.to_s)
    Rails.logger.error("json: " + e.json_body.to_s)
    throw :abort
  end
end
