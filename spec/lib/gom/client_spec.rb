require 'spec_helper'

describe Gom::Client do
  it 'exists' do
    Gom::Client.should be_kind_of(Class)
  end

  context 'VCR cassette' do
    #let(:gom)     { Gom::Client.new('http://gom.dev.artcom.de') }
    let(:gom)     { Gom::Client.new('http://127.0.0.1:3000') }
    #let(:prefix)  { gom.create!("/tests", {}) }
    #let(:prefix)  { "/tests/08ec4b58-38b3-44ac-9ea9-62b42a62b061" }

    before(:all) {
      VCR.insert_cassette('127.0.0.1:3000', :record => :new_episodes)
      # VCR.insert_cassette('gom.dev.artcom.de', :record => :new_episodes)
    }
    after(:all) {
      VCR.eject_cassette
    }

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

    pending 'updates attribute with UTF charachter' do
      uri = uniq_attr_uri
      val = 'some UTF text: öäüßÖÄÜ'
      (gom.update uri, val).should eq(val)
      (hash = gom.retrieve uri).should be_kind_of(Hash)
      hash[:attribute].should be
      hash[:attribute][:value].should eq(val)
    end

    it 'updates attribute containing ampersand' do
      uri = uniq_attr_uri
      val = 'Hallo & Ciao'
      (gom.update uri, val).should eq(val)
      (hash = gom.retrieve uri).should be_kind_of(Hash)
      hash[:attribute].should be
      hash[:attribute][:value].should eq(val)
    end

    it 'updates existing attribute to empty value' do
      uri = uniq_attr_uri
      gom.update(uri, "something")

      gom.update uri, ""
      (hash = gom.retrieve uri).should be_kind_of(Hash)
      hash[:attribute].should be
      hash[:attribute][:value].should eq('')
    end

    it 'updates new attribute to empty value' do
      uri = uniq_attr_uri
      gom.update(uri, '')
      (hash = gom.retrieve uri).should be_kind_of(Hash)
      hash[:attribute].should be
      hash[:attribute][:value].should eq('')
    end

    it 'raises a 404 on retrieval of non-existing nodes' do
      expect { gom.retrieve! "/no/such/node" }.to raise_error(
        Gom::HttpError, %r(404 Not Found\s+while GETting /no/such/node)
      )
    end

    context 'destroying things' do
      let(:nuri) { uniq_node_uri }
      let(:auri) { "#{nuri}:foo" }
      let(:val) { "wello horld!" }
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

    context 'running server side scripts' do
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

      context 'posted script' do
        it 'runs simple posted script' do
          rc = gom.run_script(:script => '"hello"')
          rc.body.should eq('hello')
          rc.code.should eq('200')
        end

        it 'passes parameter from request to the script' do
          rc = gom.run_script(script: 'params.test', :params => {test: 'p1'})
          rc.body.should eq('p1')
          rc.code.should eq('200')
        end

        it 'passes multiple parameter to script' do
          rc = gom.run_script(script: <<-JS, params: {p1: 'p1', p2: 'p2'})
            params.p1 + ':' + params.p2
          JS
          rc.body.should eq('p1:p2')
          rc.code.should eq('200')
        end

        it 'raises error on broken scripts' do
          expect { gom.run_script script: 'intentional_error' }.to raise_error(
            Gom::HttpError,
            /400 Bad Request\s+.+intentional_error is not defined/m
          )
        end
      end

      context 'stored scripts' do
        let(:script_uri) { uniq_attr_uri }

        it 'runs a simple stored script' do
          gom.update(script_uri, '"hello"')
          rc = gom.run_script(path: script_uri)
          rc.body.should eq('hello')
          rc.code.should eq('200')
        end

        it 'passes parameter from request to the script' do
          gom.update(script_uri, 'params.p1')
          rc = gom.run_script(path: script_uri, :params => {p1: 'p1'})
          rc.body.should eq('p1')
          rc.code.should eq('200')
        end

        it 'passes multiple parameter to script' do
          gom.update(script_uri, "params.p1 + ':' + params.p2")
          rc = gom.run_script(path: script_uri, params: {p1: 'p1', p2: 'p2'})
          rc.body.should eq('p1:p2')
          rc.code.should eq('200')
        end
      end
    end

    context 'observer registrations' do
      let(:cb_url) { 'http://localhost:4042/notification' }

      it 'raises on no args at all' do
        expect { gom.register_observer }.to raise_error(
          ArgumentError, /callback_url must not be nil/
        )
      end

      it 'raises on missing target node argument' do
        expect { gom.register_observer(callback_url: cb_url) }.to raise_error(
          ArgumentError, /node must not be nil/
        )
      end

      it 'raises on invalid format' do
        args = { callback_url: cb_url, node: '/some/node', format: 'Excel' }
        expect { gom.register_observer(args) }.to raise_error(
          ArgumentError, /invalid format: '#{args[:format]}'/
        )
      end

      context 'anonymous oberserver' do
        let(:target_uri) { uniq_node_uri }

        it 'registers with node and callback' do
          obs = gom.register_observer(node: target_uri, callback_url: cb_url)
          obs.should match %r(/gom/observer#{target_uri}/\..+)
          gom.retrieve_val("#{obs}:observed_uri").should eq(target_uri)
          gom.retrieve_val("#{obs}:callback_url").should eq(cb_url)
          gom.retrieve_val("#{obs}:accept").should eq("application/json")
          gom.retrieve("#{obs}:operations").should be_nil
          gom.retrieve("#{obs}:uri_regexp").should be_nil
          gom.retrieve("#{obs}:condition_script").should be_nil
          expect { gom.destroy obs }.to_not raise_error
        end

        it 'registers with filters, node and callback' do
          obs = gom.register_observer(
            node: target_uri, callback_url: cb_url, filters: {
              'operations' => 'update,create',
              'uri_regexp' => '*',
              'condition_script' => '1 === 1;'
            }
          )

          obs.should match %r(/gom/observer#{target_uri}/\..+)
          gom.retrieve_val("#{obs}:observed_uri").should eq(target_uri)
          gom.retrieve_val("#{obs}:callback_url").should eq(cb_url)
          gom.retrieve_val("#{obs}:accept").should eq("application/json")
          gom.retrieve_val("#{obs}:operations").should eq('update,create')
          gom.retrieve_val("#{obs}:uri_regexp").should eq('*')
          gom.retrieve_val("#{obs}:condition_script").should eq('1 === 1;')

          expect { gom.destroy obs }.to_not raise_error
        end
      end # ~anonymous oberserver

      context 'named observer' do
        let(:target_uri) { uniq_node_uri }
        let(:name) { "o1234" } ##{Time.now.tv_usec}" }

        it 'supports filters' do
          # with node, callback_url and filters
          obs = gom.register_observer(
            name: name, node: target_uri, callback_url: cb_url, filters: {
              'operations' => 'update,create',
              'uri_regexp' => '*',
              'condition_script' => '1 === 1;'
            }
          )

          obs.should eq("/gom/observer#{target_uri}/.#{name}")
          gom.retrieve_val("#{obs}:observed_uri").should eq(target_uri)
          gom.retrieve_val("#{obs}:callback_url").should eq(cb_url)
          gom.retrieve_val("#{obs}:accept").should eq("application/json")
          gom.retrieve_val("#{obs}:operations").should eq('update,create')
          gom.retrieve_val("#{obs}:uri_regexp").should eq('*')
          gom.retrieve_val("#{obs}:condition_script").should eq('1 === 1;')

          expect { gom.destroy obs }.to_not raise_error

          # register a second time with differnt name and changed optins to
          # check whether the destroy clean-up really works
          obs = gom.register_observer(
            name: name, node: target_uri, callback_url: cb_url
          )

          obs.should eq("/gom/observer#{target_uri}/.#{name}")
          gom.retrieve_val("#{obs}:observed_uri").should eq(target_uri)
          gom.retrieve_val("#{obs}:callback_url").should eq(cb_url)
          gom.retrieve_val("#{obs}:accept").should eq("application/json")
          gom.retrieve_val("#{obs}:operations").should be(nil)
          gom.retrieve_val("#{obs}:uri_regexp").should be(nil)
          gom.retrieve_val("#{obs}:condition_script").should be(nil)

          expect { gom.destroy obs }.to_not raise_error
        end
      end # ~ 'named observer'
    end
  end
end
