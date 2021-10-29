# frozen_string_literal: true

require 'ostruct'
require 'json'

# To run tests:
#   bundle install
#   export JSON_FILE=...
#   bundle exec rspec ./validate-json-spec.rb

# JSON_FILE is set via the pipeline task definition.
describe "#{ENV.fetch('JSON_FILE')}" do
  let(:json) { File.read(ENV['JSON_FILE']) }
  let(:events) { JSON.parse(json, object_class: OpenStruct) }

  let(:federalist_bucket_events) do
    events.select { |e| e.bucket_name.start_with?('federalist-') }
  end

  let(:cg_bucket_events) do
    events.select { |e| e.bucket_name.start_with?('cg-') }
  end

  it 'contains events for federalist/cg buckets' do
    expect(federalist_bucket_events).not_to be_empty
      or expect(cg_bucket_events).not_to be_empty
  end
end
