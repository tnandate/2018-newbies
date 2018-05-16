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
    # Since it's a decline, Stripe::CardError will be caught
    body = e.json_body
    err  = body[:error]

    puts "Status is: #{e.http_status}"
    puts "Type is: #{err[:type]}"
    puts "Charge ID is: #{err[:charge]}"
    # The following fields are optional
    puts "Code is: #{err[:code]}" if err[:code]
    puts "Decline code is: #{err[:decline_code]}" if err[:decline_code]
    puts "Param is: #{err[:param]}" if err[:param]
    puts "Message is: #{err[:message]}" if err[:message]
  rescue Stripe::RateLimitError => e
    # Too many requests made to the API too quickly
  rescue Stripe::InvalidRequestError => e
    # Invalid parameters were supplied to Stripe's API
  rescue Stripe::AuthenticationError => e
    # Authentication with Stripe's API failed
    # (maybe you changed API keys recently)
  rescue Stripe::APIConnectionError => e
    # Network communication with Stripe failed
  rescue Stripe::StripeError => e
    errors.add(:user, e.code.to_s.to_sym)
    throw :abort
  end
end
