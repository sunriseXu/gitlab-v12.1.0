# frozen_string_literal: true

require 'spec_helper'

describe Atlassian::JiraConnect::Client do
  include StubRequests

  subject { described_class.new('https://gitlab-test.atlassian.net', 'sample_secret') }

  around do |example|
    Timecop.freeze { example.run }
  end

  describe '#store_dev_info' do
    it "calls the API with auth headers" do
      dev_info_json = {
        repositories: [
          name: 'atlassian-connect-jira-example'
        ]
      }.to_json

      expected_jwt = Atlassian::Jwt.encode(
        Atlassian::Jwt.build_claims(
          issuer: Atlassian::JiraConnect.app_key,
          method: 'POST',
          uri: '/rest/devinfo/0.10/bulk'
        ),
        'sample_secret'
      )

      stub_full_request('https://gitlab-test.atlassian.net/rest/devinfo/0.10/bulk', method: :post)
        .with(
          body: dev_info_json,
          headers: {
            'Authorization' => "JWT #{expected_jwt}",
            'Content-Type' => 'application/json'
          }
        )

      subject.store_dev_info(dev_info_json)
    end
  end
end
