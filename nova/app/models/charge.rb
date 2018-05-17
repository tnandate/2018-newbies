# frozen_string_literal: true

class Charge < ApplicationRecord
  MIN_CHARGE_AMOUNT = 1
  MAX_CHARGE_AMOUNT = 100_000

  belongs_to :user

  validates :amount, numericality: { greater_than_or_equal_to: MIN_CHARGE_AMOUNT, less_than_or_equal_to: MAX_CHARGE_AMOUNT, only_integer: true }, presence: true

  enum status: { success: 0, failure: 1 }

  before_create :create_stripe_charge

  protected

  def create_stripe_charge
    res = Stripe::Charge.create(
      amount: amount,
      currency: 'jpy',
      customer: user.stripe_id
    )

    self.ch_id = res.id
  rescue Stripe::StripeError => e
    Rails.logger.error('code: ' + e.code.to_s)
    Rails.logger.error('http_status: ' + e.http_status.to_s)
    Rails.logger.error('json: ' + e.json_body.to_s)

    # StripeError が発生した場合 status を failure にして db に保存する
    self.status = 'failure'
    self.ch_id = res.id
  end
end
