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
  rescue Stripe::CardError, Stripe::StripeError => e
    errors.add(:base, "Stripeでエラーが発生しました。少々お待ちください。")
    throw :abort
  end
end
