# frozen_string_literal: true

class Charge < ApplicationRecord
  MIN_CHARGE_AMOUNT = 1
  MAX_CHARGE_AMOUNT = 100_000

  belongs_to :user

  validates :amount, numericality: { greater_than_or_equal_to: MIN_CHARGE_AMOUNT, less_than_or_equal_to: MAX_CHARGE_AMOUNT, only_integer: true }, presence: true

  after_create :create_stripe_charge

  protected

  def create_stripe_charge
    Stripe::Charge.create(
      amount: amount,
      currency: 'jpy',
      customer: user.stripe_id
    )
  rescue Stripe::CardError => e
    throw :abort
  rescue Stripe::RateLimitError => e
    throw :abort
  rescue Stripe::InvalidRequestError => e
    throw :abort
  rescue Stripe::AuthenticationError => e
    throw :abort
  rescue Stripe::APIConnectionError => e
    throw :abort
  rescue Stripe::StripeError => e
    Rails.logger.error(e.code)
    Rails.logger.error(e.http_status)
    Rails.logger.error(e.json_body)
    throw :abort
  end
end
