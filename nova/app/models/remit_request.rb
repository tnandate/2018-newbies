# frozen_string_literal: true

class RemitRequest < ApplicationRecord
  MIN_REMIT_AMOUNT = 1
  MAX_REMIT_AMOUNT = 100_000

  belongs_to :user
  belongs_to :target, class_name: 'User'

  validates :amount, numericality: { greater_than_or_equal_to: MIN_REMIT_AMOUNT, less_than_or_equal_to: MAX_REMIT_AMOUNT, only_integer: true }, presence: true
  validate :validate_equal_user_and_target
  validate :validate_nonexist_target
  enum status: { outstanding: 0, accepted: 1, rejected: 2, canceled: 3, errored: 4 }

  # remit_requestモデルが作成された時の状態は outstanding
  # そこから１方向に変化する。(accepted, rejected, canceled, errored のどれか)
  # 2度以上状態が変化しない。

  private

  def validate_equal_user_and_target
    if user.email == target.email
      errors.add(:base, '自分宛にリクエストは作成できません。')
    end
  end

  def validate_nonexist_target
    if User.where(email: target.email).blank?
      errors.add(:base, '登録されていないユーザーです。')
    end
  end
end
