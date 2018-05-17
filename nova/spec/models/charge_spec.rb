# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Charge, type: :model do
  describe 'factory validation' do
    subject { build(:charge) }

    it { is_expected.to be_valid }
  end

  describe 'Validations' do
    it { is_expected.to belong_to(:user) }
  end

  context 'Error handlings' do
    context 'Card Error' do
      let(:instance) { build(:charge) }
      before do
        StripeMock.prepare_card_error(:card_declined)
      end

      it 'mocks a declined card error' do
        expect(instance.save).to be false
        expect(instance.errors.messages).to be_present
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
