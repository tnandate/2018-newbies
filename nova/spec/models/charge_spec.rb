# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Charge, type: :model do
  describe 'factory validation' do
    subject(:charge) { build(:charge) }

    it { is_expected.to be_valid }
  end

  describe 'Validations' do
    it { is_expected.to belong_to(:user) }
  end

  context 'Error handlings' do
    context 'Card Error' do
      it 'mocks a declined card error' do
        StripeMock.prepare_card_error(:card_declined)

        expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error {|e|
          expect(e).to be_a Stripe::CardError
          expect(e.http_status).to eq(402)
          expect(e.code).to eq('card_declined')
        }
      end
    end
  end

  describe 'Associations' do
    describe 'amount' do
      it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(100_000).only_integer }
      it { is_expected.to validate_presence_of(:amount) }
    end
  end
end
