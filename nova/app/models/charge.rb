# frozen_string_literal: true

class Charge < ApplicationRecord
  belongs_to :user

  validates_inclusion_of :amount, in: [100, 500, 1000, 5000]

  after_create :create_stripe_charge

  protected

  def create_stripe_charge
    Stripe::Charge.create(
      amount: amount,
      currency: 'jpy',
      customer: user.stripe_id
    )
  rescue Stripe::StripeError => e
    errors.add(:user, e.code.to_s.to_sym)
    throw :abort
  end
end
