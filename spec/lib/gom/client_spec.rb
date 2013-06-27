require 'spec_helper'

describe Gom::Client do 
  it 'exists' do
    Gom::Client.should be_kind_of(Class)
  end

  context 'with gom.dev.artcom.de' do 
    #let(:gom)     { Gom::Client.new('http://gom.dev.artcom.de') }
    let(:gom)     { Gom::Client.new('http://127.0.0.1:3000') }
    #let(:prefix)  { gom.create!("/tests", {}) }
    #let(:prefix)  { "/tests/08ec4b58-38b3-44ac-9ea9-62b42a62b061" }


    it 'creates and retrieves new node with no attributes' do
      (uri = gom.create!("/tests/1", {})).should match(%r(/tests/1/\w+))
      (hash = gom.retrieve uri).should be_kind_of(Hash)
      (node = hash[:node]).should be_kind_of(Hash)
      node[:uri].should eq(uri)
      node[:entries].should eq([])
    end

    it 'creates and retrieves new node with some attributes' do
      values = {:x => :u, :a => 23}
      (uri = gom.create!("/tests/2", values)).should match(%r(/tests/2/\w+))
      (hash = gom.retrieve uri).should be_kind_of(Hash)
      (node = hash[:node]).should be_kind_of(Hash)
      node[:uri].should eq(uri)
      node[:entries].size.should be(2)

      (hash = gom.retrieve "#{uri}:x").should be_kind_of(Hash)
      hash[:attribute].should be_kind_of(Hash)
      hash[:attribute][:value].should eq('u')

      (hash = gom.retrieve "#{uri}:a").should be_kind_of(Hash)
      hash[:attribute].should be_kind_of(Hash)
      hash[:attribute][:value].should eq('23')
    end

    context 'with parent node' do 
      let(:nuri) { uniq_node_uri }
      before(:each) { gom.update nuri }

      it 'updates node with attributes' do
        values = { "foo1" => "val1", "foo2" => "val2" }
        (h = gom.update nuri, values).should be_kind_of(Hash)
        h[:status].should eq(200)
      end
    end
  
    it 'updates and retrieves attributes' do
      uri = uniq_attr_uri
      val = 'some text'
      (gom.update uri, val).should eq(val)
      (hash = gom.retrieve uri).should be_kind_of(Hash)
      hash[:attribute].should be
      hash[:attribute][:value].should eq(val)
    end

    it 'raises a 404 on retrieval of non-existing nodes' do
      expect { gom.retrieve! "/no/such/node" }.to raise_error(
        Gom::HttpError, %r(404 Not Found\s+while GETting /no/such/node)
      )
    end

    context 'destroying things' do
      let(:nuri) { uniq_node_uri }
      let(:auri) { "#{nuri}:foo" }
      let(:val) { Time.now.to_s }
      before(:each) { (gom.update auri, val).should eq(val) }

      it 'destroys attributes' do
        expect{gom.destroy auri}.to_not raise_error
        gom.retrieve(auri).should be(nil)
        expect { gom.retrieve!(auri) }.to raise_error(
          Gom::HttpError, %r(404 Not Found\s+while GETting #{auri})
        )
      end

      it 'destroys nodes' do
        expect{gom.destroy nuri}.to_not raise_error
        gom.retrieve(nuri).should be(nil)

        expect { gom.retrieve!(nuri) }.to raise_error(
          Gom::HttpError, %r(404 Not Found\s+while GETting #{nuri})
        )
        expect { gom.retrieve!(auri) }.to raise_error(
          Gom::HttpError, %r(404 Not Found\s+while GETting #{auri})
        )
      end

      it 'destroys non-existing node' do
        expect { gom.destroy!(nuri) }.to_not raise_error
      end

      it 'destroys non-existing attribute' do
        expect { gom.destroy!(auri) }.to_not raise_error
      end
    end

    context 'running scripts' do
      it 'raises on script AND path over-specified request' do
        expect { 
          gom.run_script(:script => "something", :path  => "something else")
        }.to raise_error(
          ArgumentError, %r(must not provide script AND path)
        )
      end
        
      it 'raises on script NOR path under-specified request' do
        expect { gom.run_script }.to raise_error(
          ArgumentError, %r(must provide script OR path)
        )
      end


      it 'runs simple posted script' do
        # simple script
        rc = gom.run_script(:script => <<-JS)
          response.body = "hello";
          "200 OK";
        JS

        rc.body.should eq('hello')
        rc.code.should eq(200)
      end

      pending 'runs more scripts' do
        # script with one parameter
        my_script = <<-JS
          response.body=params.test;
          "200 OK";
        JS
        my_result = gom.run_script :script => my_script,
                                       :params => {:test => "param_value"}
        assert_equal "param_value", my_result.body
        assert_equal "200",         my_result.code
        
        # script with multiple parameters
        my_script = <<-JS
          response.body=params.test + ":" + params.test2;
          "200 OK";
        JS
        my_result = gom.run_script :script => my_script,
                                       :params => {:test  => "param_value",
                                                   :test2 => "param_valuer"}
        assert_equal "param_value:param_valuer", my_result.body
        assert_equal "200",         my_result.code
        
        # Script with an error
        my_script = <<-JS
          response.body=something_undefined;
          "200 OK";
        JS
        my_exception = assert_raise(RestFs::HttpError) do
           gom.run_script :script => my_script
        end
        
        assert_equal "500 Internal Server Error while executing server-side-script:\nexception:\nsomething_undefined is not defined at (immediate script):1\n",
                     my_exception.to_s
      end
    end
  end
end

__END__
  
  def test_run_posted_script
    # simple script
    my_script = <<-JS
      response.body="hello";
      "200 OK";
    JS
    my_result = @restfs.run_script :script => my_script
    assert_equal "hello", my_result.body
    assert_equal "200",   my_result.code
    
    # script with one parameter
    my_script = <<-JS
      response.body=params.test;
      "200 OK";
    JS
    my_result = @restfs.run_script :script => my_script,
                                   :params => {:test => "param_value"}
    assert_equal "param_value", my_result.body
    assert_equal "200",         my_result.code
    
    # script with multiple parameters
    my_script = <<-JS
      response.body=params.test + ":" + params.test2;
      "200 OK";
    JS
    my_result = @restfs.run_script :script => my_script,
                                   :params => {:test  => "param_value",
                                               :test2 => "param_valuer"}
    assert_equal "param_value:param_valuer", my_result.body
    assert_equal "200",         my_result.code
    
    # Script with an error
    my_script = <<-JS
      response.body=something_undefined;
      "200 OK";
    JS
    my_exception = assert_raise(RestFs::HttpError) do
       @restfs.run_script :script => my_script
    end
    
    assert_equal "500 Internal Server Error while executing server-side-script:\nexception:\nsomething_undefined is not defined at (immediate script):1\n",
                 my_exception.to_s
  end
  
  def test_run_stored_script
    # simple script
    my_script = <<-JS
      response.body="hello";
      "200 OK";
    JS
    @restfs.update("#{@prefix}:my_stored_script", my_script)
    my_result = @restfs.run_script :path => "#{@prefix}/my_stored_script"
    assert_equal "hello", my_result.body
    assert_equal "200",   my_result.code
    
    #one parameter
    my_script = <<-JS
      response.body=params.test;
      "200 OK";
    JS
    @restfs.update("#{@prefix}:my_stored_script", my_script)
    my_result = @restfs.run_script :path => "#{@prefix}/my_stored_script",
                                   :params => {:test => "param_value"}
    assert_equal "param_value", my_result.body
    assert_equal "200",         my_result.code
    
    # script with multiple parameters
    my_script = <<-JS
      response.body=params.test + ":" + params.test2;
      "200 OK";
    JS
    @restfs.update("#{@prefix}:my_stored_script", my_script)
    my_result = @restfs.run_script :path => "#{@prefix}/my_stored_script",
                                   :params => {:test  => "param_value",
                                               :test2 => "param_valuer"}
    assert_equal "param_value:param_valuer", my_result.body
    assert_equal "200",         my_result.code
  end
  
  def test_register_observer_invalid_arguments
    my_node     = "/testerino"
    my_callback = "http://localhost:4042/notification"
    
    my_exception = assert_raise(ArgumentError) do 
      @restfs.register_observer
    end
    assert_equal 'callback_url must not be nil', my_exception.message
    
    my_exception = assert_raise(ArgumentError) do 
      @restfs.register_observer :callback_url => my_callback
    end
    assert_equal 'node must not be nil', my_exception.message
    
    my_exception = assert_raise(ArgumentError) do 
      @restfs.register_observer :callback_url => my_callback,
                                :node         => my_node,
                                :format       => "Excel"
    end
    assert_equal 'invalid format', my_exception.message
  end
  
  def test_register_unnamed_observer
    my_node     = "/testerino"
    my_callback = "http://localhost:4042/notification"
    
    # with node and callback_url
    my_observer = @restfs.register_observer :node         => my_node,
                                            :callback_url => my_callback
    assert_equal true, my_observer.start_with?("/gom/observer#{my_node}/.")
    assert_equal true, my_observer.size > "/gom/observer#{my_node}/.".size
    assert_equal my_node,            @restfs.retrieve("#{my_observer}:observed_uri")[:attribute][:value]
    assert_equal my_callback,        @restfs.retrieve("#{my_observer}:callback_url")[:attribute][:value]
    assert_equal "application/json", @restfs.retrieve("#{my_observer}:accept")[:attribute][:value]
    assert_equal nil,                @restfs.retrieve("#{my_observer}:operations")
    assert_equal nil,                @restfs.retrieve("#{my_observer}:uri_regexp")
    assert_equal nil,                @restfs.retrieve("#{my_observer}:condition_script")
    @restfs.destroy my_observer
    
    # with node, callback_url and filters
    my_observer = @restfs.register_observer :node         => my_node,
                                            :callback_url => my_callback,
                                            :filters      => { "operations" => "update,create",
                                                               "uri_regexp" => "*",
                                                               'condition_script' => "response.body = 'hello';'200 OK';" }
    assert_equal true, my_observer.start_with?("/gom/observer#{my_node}/.")
    assert_equal true, my_observer.size > "/gom/observer#{my_node}/.".size
    assert_equal my_node,            @restfs.retrieve("#{my_observer}:observed_uri")[:attribute][:value]
    assert_equal my_callback,        @restfs.retrieve("#{my_observer}:callback_url")[:attribute][:value]
    assert_equal "application/json", @restfs.retrieve("#{my_observer}:accept")[:attribute][:value]
    assert_equal 'update,create',    @restfs.retrieve("#{my_observer}:operations")[:attribute][:value]
    assert_equal '*',                @restfs.retrieve("#{my_observer}:uri_regexp")[:attribute][:value]
    assert_equal "response.body = 'hello';'200 OK';",
                 @restfs.retrieve("#{my_observer}:condition_script")[:attribute][:value]
    @restfs.destroy my_observer
  end
  
  def test_register_named_observer
    my_node          = "/testerino"
    my_callback      = "http://localhost:4042/notification"
    my_observer_name = "my_test_observer_name"
    
    # with node, callback_url and filters
    my_observer = @restfs.register_observer :name         => my_observer_name,
                                            :node         => my_node,
                                            :callback_url => my_callback,
                                            :filters      => { "operations" => "update,create",
                                                               "uri_regexp" => "*",
                                                               'condition_script' => "response.body = 'hello';'200 OK';" }
    assert_equal "/gom/observer#{my_node}/.#{my_observer_name}", my_observer
    assert_equal my_node,            @restfs.retrieve("#{my_observer}:observed_uri")[:attribute][:value]
    assert_equal my_callback,        @restfs.retrieve("#{my_observer}:callback_url")[:attribute][:value]
    assert_equal "application/json", @restfs.retrieve("#{my_observer}:accept")[:attribute][:value]
    assert_equal 'update,create',    @restfs.retrieve("#{my_observer}:operations")[:attribute][:value]
    assert_equal '*',                @restfs.retrieve("#{my_observer}:uri_regexp")[:attribute][:value]
    assert_equal "response.body = 'hello';'200 OK';",
                 @restfs.retrieve("#{my_observer}:condition_script")[:attribute][:value]
    @restfs.destroy my_observer
    
    # with node and callback_url
    # This also tests that the observer should be deleted before recreating it
    # with the same name
    my_observer = @restfs.register_observer :name         => my_observer_name,
                                            :node         => my_node,
                                            :callback_url => my_callback
    assert_equal "/gom/observer#{my_node}/.#{my_observer_name}", my_observer
    assert_equal my_node,            @restfs.retrieve("#{my_observer}:observed_uri")[:attribute][:value]
    assert_equal my_callback,        @restfs.retrieve("#{my_observer}:callback_url")[:attribute][:value]
    assert_equal "application/json", @restfs.retrieve("#{my_observer}:accept")[:attribute][:value]
    assert_equal nil,                @restfs.retrieve("#{my_observer}:operations")
    assert_equal nil,                @restfs.retrieve("#{my_observer}:uri_regexp")
    assert_equal nil,                @restfs.retrieve("#{my_observer}:condition_script")
    @restfs.destroy my_observer
  end

  def test_update_attr_containing_ampersand
    @restfs.update "#{@prefix}:my_attr", "Hallo & Ciao"
    assert_equal "Hallo & Ciao", @restfs.retrieve("#{@prefix}:my_attr")[:attribute][:value]
  end

  def test_update_attr_to_empty_value
    @restfs.update "#{@prefix}:my_attr", "something"
    assert_equal "something", @restfs.retrieve("#{@prefix}:my_attr")[:attribute][:value]
    
    @restfs.update "#{@prefix}:my_attr", ""
    assert_equal "", @restfs.retrieve("#{@prefix}:my_attr")[:attribute][:value]
    
    @restfs.update "#{@prefix}:my_new_attr", ""
    assert_equal "", @restfs.retrieve("#{@prefix}:my_new_attr")[:attribute][:value]
  end

