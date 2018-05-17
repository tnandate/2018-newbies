# frozen_string_literal: true

class Charge < ApplicationRecord
  belongs_to :user

  validates_inclusion_of :amount, in: [100, 500, 1000, 5000]

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
    # error として返って来た json に ch_id があれば Charge model の ch_id に突っ込む
    self.ch_id = e.json_body&.[](:error)&.[](:charge)
  end
end
