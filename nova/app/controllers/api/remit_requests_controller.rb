# frozen_string_literal: true

class Api::RemitRequestsController < Api::ApplicationController
  def index
    @sent_remit_requests = current_user.sent_remit_requests.send(params[:status] || 'outstanding').order(id: :desc).limit(50)
    @remit_requests = current_user.received_remit_requests.send(params[:status] || 'outstanding').order(id: :desc).limit(50)

    render json: {sent: @sent_remit_requests.as_json(include: :user), request: @remit_requests.as_json(include: :user)}
  end

  def create
    params[:emails].each do |email|
      user = User.find_by(email: email.downcase)
      next unless user

      RemitRequest.create!(user: current_user, target: user, amount: params[:amount])
    end

    render json: {}, status: :created
  end

  def accept
    @remit_request = RemitRequest.find(params[:id])
    @remit_request.update!(accepted_at: Time.now)

    # 残高の更新
    sender =  @remit_request.target
    receiver = @remit_request.user
    #悲観的ロック
    sender.balance.lock!
    sender.balance.amount -= @remit_request.amount
    receiver.balance.amount += @remit_request.amount
    sender.balance.save!
    receiver.balance.save!

    render json: {}, status: :ok
  end

  def reject
    @remit_request = RemitRequest.find(params[:id])
    @remit_request.update!(rejected_at: Time.now)

    render json: {}, status: :ok
  end

  def cancel
    @remit_request = RemitRequest.find(params[:id])
    @remit_request.update!(canceled_at: Time.now)

    render json: {}, status: :ok
  end
end
