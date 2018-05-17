require 'rails_helper'

RSpec.describe Balance, type: :model do

  describe 'Association' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    describe 'amount' do
      it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100_000).only_integer }
      it { is_expected.to validate_presence_of(:amount) }
    end
  end
end
