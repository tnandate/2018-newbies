# frozen_string_literal: true

class Api::ChargesController < Api::ApplicationController
  def index
    @charges = current_user.charges.order(id: :desc).limit(50)

    render json: { amount: current_user.balance, charges: @charges }
  end

  def create
    @charge = current_user.charges.create!(amount: params[:amount])
    current_user.balance += params[:amount]
    p current_user.balance
    current_user.save
    p current_user.balance
    render json: @charge, status: :created
  rescue ActiveRecord::RecordInvalid => e
    record_invalid(e)
  end
end
