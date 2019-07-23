# frozen_string_literal: true

require_relative '../test_helper'

# Test for the Token Refresh Sequence
# See : https://tools.ietf.org/html/rfc6749#section-6
class TokenRefreshSequenceTest < MiniTest::Test
  def setup
    refresh_token = JSON::JWT.new(iss: 'foo_refresh')
    @instance = Inferno::Models::TestingInstance.new(
      url: 'http://www.example.com',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
      client_id: SecureRandom.uuid,
      selected_module: 'argonaut',
      oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
      oauth_token_endpoint: 'http://oauth_reg.example.com/token',
      initiate_login_uri: 'http://localhost:4567/launch',
      redirect_uris: 'http://localhost:4567/redirect',
      scopes: 'launch openid patient/*.* profile',
      refresh_token: refresh_token
    )

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::TokenRefreshSequence.new(@instance, client, true)
    @standalone_token_exchange = load_json_fixture(:standalone_token_exchange)
  end

  def setup_mocks
    WebMock.reset!

    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
    }
    body = {
      'grant_type' => 'refresh_token',
      'refresh_token' => @instance.refresh_token
    }

    if @instance.client_secret.present?
      headers['Authorization'] = "Basic #{Base64.strict_encode64(@instance.client_id + ':' + @instance.client_secret)}"
    else
      body['client_id'] = @instance.client_id
    end

    stub_request(:post, @instance.oauth_token_endpoint)
      .with(headers: headers,
            body: body)
      .to_return(status: 200,
                 body: @standalone_token_exchange.to_json,
                 headers: { content_type: 'application/json; charset=UTF-8',
                            cache_control: 'no-store',
                            pragma: 'no-cache' })

    # To test rejection of invalid client_id
    stub_request(:post, @instance.oauth_token_endpoint)
      .with(body: /INVALID/,
            headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
      .to_return(status: 401)
  end

  def all_pass
    setup_mocks
    sequence_result = @sequence.start

    assert sequence_result.pass?, 'The sequence should be marked as pass.'
  end

  def test_all_pass_confidential_client
    @instance.client_secret = SecureRandom.uuid
    @instance.confidential_client = true
    all_pass
  end

  def test_all_pass_public_client
    @instance.client_secret = nil
    @instance.confidential_client = nil
    all_pass
  end
end
