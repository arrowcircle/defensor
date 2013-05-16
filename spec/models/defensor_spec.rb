# coding: utf-8

require 'spec_helper'

describe Defensor do
  before { Defensor.api_key = ENV['DEFENSIO_KEY'] }

  context "initialize" do
    let(:defensor_no_key) { Defensor.api_key = nil; Defensor.new({}) }
    let(:defensor) { Defensor.api_key = "ABC"; Defensor.new({type: :forum, platform: :movable_type, nonrelevant: :abc}) }

    it "Accepts input params with key" do
      expect(defensor.options.keys).not_to include "nonrelevant"
    end

    it "Throws Exception if api_key not set" do
      lambda { defensor_no_key }.should raise_exception(Defensor::NoApiKeyException)
    end
  end

  context ".api_path" do

    it "returns valid url with no options" do
      expect(Defensor.api_path).to eq "/#{Defensor::API_VERSION}/users/#{Defensor.api_key}.json"
    end

    it "returns valid url with action" do
      expect(Defensor.api_path("action")).to eq "/#{Defensor::API_VERSION}/users/#{Defensor.api_key}/action.json"
    end

    it "returns valid url with action and id" do
      expect(Defensor.api_path("action", "id")).to eq "/#{Defensor::API_VERSION}/users/#{Defensor.api_key}/action/id.json"
    end
  end

  if ENV['DEFENSIO_KEY']

    context "real_requests" do
      before { Defensor.api_key = ENV['DEFENSIO_KEY'] }

      context ".get_user" do
        let(:get_user) { Defensor.get_user }

        it "returns valid response" do
          status, body = get_user
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body['status']).to eq "success"
        end
      end

      context ".get_basic_stats" do
        let(:stats) { Defensor.get_basic_stats }

        it "returns valid result" do
          status, body = stats
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body['status']).to eq "success"
          expect(body["unwanted"]["total"].is_a? Integer).to eq true
        end
      end

      context ".get_extended_stats" do
        let(:stats) { Defensor.get_extended_stats(:from => Date.new(2009, 9, 1), :to => Date.new(2009, 9, 3)) }

        it "returns valid result" do
          status, body = stats
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body['data'].is_a? Array).to eq true
          expect(body["data"][0]["date"].is_a? Date ).to eq true if body["data"].size > 0
        end
      end

      context ".post_profanity_filter" do
        let(:stats) { Defensor.post_profanity_filter("field1"=>"hello world", "other_field"=>"hello again") }

        it "returns valid result" do
          status, body = stats
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body["filtered"].is_a? Hash).to eq true
          expect(body["filtered"].keys).to include "field1"
          expect(body["filtered"].keys).to include "other_field"
        end
      end

      context ".parse_body" do
        let(:body) { Defensor.parse_body '{"defensio-result":{"hello":"world"}}'}
        let(:result) { {"hello" => "world"} }

        it "returns valid result" do
          expect(body).to eq result
        end
      end

      context "#post_document" do
        let(:defensor) { Defensor.new({type: :forum, platform: :movable_type, nonrelevant: :abc, content: "My test content for defensor"}) }
        let(:response) { defensor.post_document }

        it "puts document to defensio and sets signature" do
          status, body = response
          expect(defensor.signature).to eq body["signature"]
          expect(status).to eq 200
        end
      end

      context ".handle_post_document_async_callback__string" do
        require 'ostruct'
        let(:result) { { "defensio-result" =>
               { "api-version"       => Defensor::API_VERSION,
                 "status"            => "success",
                 "message"           => nil,
                 "signature"         => "123456",
                 "allow"             => false,
                 "classification"    => "malicious",
                 "spaminess"         => 0.95,
                 "profanity-match"  => true }
              } }
        let(:request) { OpenStruct.new(:body => StringIO.new(result.to_json)) }

        it "checks string" do
          expect(Defensor.handle_post_document_async_callback(result.to_json).class).to eq Hash
        end

        it "checks object" do
          result = Defensor.handle_post_document_async_callback(request)
          expect(result.class).to eq Hash
          expect(result["status"]).to eq "success"
        end
      end

      context "integration" do
        let(:defensor) { Defensor.api_key = ENV['DEFENSIO_KEY']; Defensor.new({:content => "This is a simple test", :platform => "
          my_test_platform", :type => "comment"}) }
        let(:post) { defensor.post_document }

        it "test post get put" do
          status, body = post
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body["status"]).to eq "success"
          expect(defensor.signature).to eq body["signature"]

          # Keep some variables around
          original_allow_result = body["allow"]

          sleep 0.5

          # GET
          status, body = defensor.get_document
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body["status"]).to eq "success"
          expect(defensor.signature).to eq body["signature"]

          # PUT
          status, body = defensor.put_document(:allow => !original_allow_result)
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body["status"]).to eq "success"
          expect(defensor.signature).to eq body["signature"]
          expect(body["allow"]).to eq !original_allow_result

          status, body = defensor.put_document(:allow => original_allow_result)
          expect(body.is_a? Hash).to eq true
          expect(status).to eq 200
          expect(body["status"]).to eq "success"
          expect(defensor.signature).to eq body["signature"]
          expect(body["allow"]).to eq original_allow_result
        end
      end

    end # context "real_requests"
  end # if ENV['DEFENSIO_KEY']

end