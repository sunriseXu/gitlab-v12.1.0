# frozen_string_literal: true

require 'rails_helper'

describe ::EE::NullNotificationService do
  it 'responds to methods implemented by NotificationService' do
    method = NotificationService.instance_methods(false).sample

    expect(subject.public_send(method)).to be_instance_of(described_class)
  end

  it 'raises NoMethodError for methods not implemented by NotificationService' do
    expect { subject.not_a_real_method }.to raise_error(NoMethodError)
  end
end
