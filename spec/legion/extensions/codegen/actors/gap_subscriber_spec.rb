# frozen_string_literal: true

require 'spec_helper'

# GapSubscriber requires Legion::Extensions::Actors::Subscription (LegionIO runtime).
# In standalone gem specs the base class is unavailable, so the actor file early-returns.
RSpec.describe 'Legion::Extensions::Codegen::Actor::GapSubscriber' do
  it 'is not loaded without the LegionIO runtime' do
    expect(defined?(Legion::Extensions::Codegen::Actor::GapSubscriber)).to be_falsey
  end
end
