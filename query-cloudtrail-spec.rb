# frozen_string_literal: true

# To run tests:
#   bundle install
#   bundle exec rspec ./query-cloudtrail-spec.rb

require './query-cloudtrail'

describe '#cg_client_creds' do
  it 'returns the client config' do
    file = 'terraform-yaml/state.yml'
    yaml = YAML.load(<<-YAML)
    terraform_outputs:
      federalist_auditor_access_key_id_curr: ID
      federalist_auditor_secret_access_key_curr: SECRET
    YAML

    expect(YAML).
      to receive(:load_file).
      at_least(:once).
      with(file).
      and_return(yaml)

    exected = { access_key_id: 'ID', secret_access_key: 'SECRET' }
    expect(cg_client_creds(file)).to eq(exected)
  end

  it 'explodes without env vars set' do
    file = 'terraform-yaml/state.yml'
    yaml = YAML.load('terraform_outputs: {}')
    expect(YAML).
      to receive(:load_file).
      at_least(:once).
      with(file).
      and_return(yaml)
    expect { cg_client_creds(file) }.to raise_error(KeyError)
  end
end

describe '#fed_client_creds' do
  it 'returns the client config' do
    ENV["FED_AWS_ACCESS_KEY_ID"] = "ID"
    ENV["FED_AWS_SECRET_ACCESS_KEY"] = "SECRET"
    exected = { access_key_id: 'ID', secret_access_key: 'SECRET' }
    expect(fed_client_creds).to eq(exected)
  end

  it 'explodes without env vars set' do
    ENV.delete("FED_AWS_ACCESS_KEY_ID")
    ENV.delete("FED_AWS_SECRET_ACCESS_KEY")
    expect { fed_client_creds }.to raise_error(KeyError)
  end
end

describe '#old_buckets' do
  it 'returns list of buckets from env' do
    ENV['OLD_BUCKETS'] = "one two"
    expect(old_buckets).to eq(["one", "two"])
  end
end

describe '#new_buckets' do
  it 'returns all federalist s3 buckets' do
    client = Aws::S3::Client.new(stub_responses: true)
    client.stub_responses(:list_buckets,
                      { buckets: [
                        { name: "federalist-one" },
                        { name: "another-bucket" },
                        { name: "federalist-two" }]})

    expect(Aws::S3::Client).
      to receive(:new).
      with('fake_fed_creds').
      and_return(client)
    expect_any_instance_of(Object).
      to receive(:fed_client_creds).
      and_return('fake_fed_creds')

    expect(new_buckets).
      to eq(['federalist-one', 'federalist-two'])
  end
end

describe '#events_for_bucket' do
  before do
    client = Aws::CloudTrail::Client.new(stub_responses: true)
    client.stub_responses(:lookup_events,
                      { events: [
                        { event_id: "one", event_time: Time.now.localtime },
                        { event_id: "two", event_time: Time.now.localtime }]})

    expect(Aws::CloudTrail::Client).
      to receive(:new).
      with('fake_fed_creds').
      and_return(client)

    expect_any_instance_of(Object).
      to receive(:fed_client_creds).
      and_return('fake_fed_creds')
  end

  it 'returns all cloudtrail events for a bucket' do
    expect(events_for_bucket('foo').map {|e| e[:event_id]}).to eq(['one', 'two'])
  end

  it 'uses UTC timestamps' do
    expect(events_for_bucket('foo')[0][:event_time]).to be_utc
  end

  it 'sleeps to avoid rate limiting' do
    expect_any_instance_of(Object).to receive(:sleep).and_return(:sleep)
    events_for_bucket('foo')
  end
end

describe '#add_bucket_events(list, buckets)' do
  it 'adds the events to the list' do
    expect_any_instance_of(Object).
      to receive(:events_for_bucket).
      with("bucket").
      and_return(["three"])

    events = ["one", "two"]
    add_bucket_events(events, ["bucket"])

    expect(events).to eq(["one", "two", "three"])
  end

  it "doesn't add empty event lists to the list" do
    expect_any_instance_of(Object).
      to receive(:events_for_bucket).
      with("bucket").
      and_return([])

    events = ["one", "two"]
    add_bucket_events(events, ["bucket"])

    expect(events).to eq(["one", "two"])
  end
end
