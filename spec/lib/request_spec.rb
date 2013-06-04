require 'spec_helper'

describe ActiveRestClient::Request do
  before :each do
    class ExampleClient < ActiveRestClient::Base
      base_url "http://www.example.com"

      get :all, "/"
      get :find, "/:id"
      post :create, "/create"
      put :update, "/put/:id"
      delete :remove, "/remove/:id"
    end
  end

  it "should get an HTTP connection when called" do
    connection = double(ActiveRestClient::Connection)
    ExampleClient.should_receive(:get_connection).and_return(connection)
    connection.should_receive(:get).with("/").and_return(OpenStruct.new(body:'{"result":true}'))
    ExampleClient.all
  end

  it "should get an HTTP connection when called and call get on it" do
    ActiveRestClient::Connection.any_instance.should_receive(:get).with("/").and_return(OpenStruct.new(body:'{"result":true}'))
    ExampleClient.all
  end

  it "should pass through get parameters" do
    ActiveRestClient::Connection.any_instance.should_receive(:get).with("/?debug=true").and_return(OpenStruct.new(body:'{"result":true}'))
    ExampleClient.all debug:true
  end

  it "should pass through url parameters" do
    ActiveRestClient::Connection.any_instance.should_receive(:get).with("/1234").and_return(OpenStruct.new(body:'{"result":true}'))
    ExampleClient.find id:1234
  end

  it "should pass through url parameters and get parameters" do
    ActiveRestClient::Connection.any_instance.should_receive(:get).with("/1234?debug=true").and_return(OpenStruct.new(body:"{\"result\":true}"))
    ExampleClient.find id:1234, debug:true
  end

  it "should pass through url parameters and put parameters" do
    ActiveRestClient::Connection.any_instance.should_receive(:put).with("/put/1234", "debug=true").and_return(OpenStruct.new(body:"{\"result\":true}"))
    ExampleClient.update id:1234, debug:true
  end

  it "should parse JSON to give a nice object" do
    ActiveRestClient::Connection.any_instance.should_receive(:put).with("/put/1234", "debug=true").and_return(OpenStruct.new(body:"{\"result\":true, \"list\":[1,2,3,{\"test\":true}], \"child\":{\"grandchild\":{\"test\":true}}}"))
    object = ExampleClient.update id:1234, debug:true
    expect(object.result).to eq(true)
    expect(object.list.first).to eq(1)
    expect(object.list.last.test).to eq(true)
    expect(object.child.grandchild.test).to eq(true)
  end

  it "should assign new attributes to the existing object if possible" do
    ActiveRestClient::Connection.
      any_instance.
      should_receive(:post).
      with("/create", "first_name=John&should_disappear=true").
      and_return(OpenStruct.new(body:"{\"first_name\":\"John\", \"id\":1234}"))
    object = ExampleClient.new(first_name:"John", should_disappear:true)
    object.create
    expect(object.first_name).to eq("John")
    expect(object.should_disappear).to eq(nil)
    expect(object.id).to eq(1234)
  end

end