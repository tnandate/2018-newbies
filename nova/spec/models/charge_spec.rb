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

  describe 'Associations' do
    describe 'amount' do
      it { should validate_inclusion_of(:amount).in_array([100, 500, 1000, 5000]) }
    end
  end
end
