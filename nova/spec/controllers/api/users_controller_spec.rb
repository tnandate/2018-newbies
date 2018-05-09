# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #show' do
    subject { get :show }

    context 'without logged in' do
      it { is_expected.to have_http_status(:unauthorized) }
    end

    context 'with logged in' do
      before { login!(user) }

      it { is_expected.to have_http_status(:ok) }
    end
  end

  describe 'PUT #update' do
    let(:user_params) { { user: {} } }
    subject { put :update, params: user_params }

    context 'without logged in' do
      it { is_expected.to have_http_status(:unauthorized) }
    end

    context 'with logged in' do
      before { login!(user) }

      context 'with invalid params' do
        let(:user_params) { {} }

        it { is_expected.to have_http_status(:unprocessable_entity) }
      end

      context 'with invalid record params' do
        let(:user_params) { { user: { email: '' } } }

        it { is_expected.to have_http_status(:unprocessable_entity) }
      end

      context 'with valid params' do
        let(:user_params) { { user: { nickname: 'John Doe', email: 'valid@email.com' } } }

        it { is_expected.to have_http_status(:ok) }
      end
    end
  end
end
