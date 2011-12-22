require 'spec_helper'


describe "Rainman::Driver" do
  describe Rainman::Driver do
    it { Rainman::Driver::Configuration.should be_a(Hash) }
    it { Rainman::Driver::Validations.should be_a(Hash) }
  end


  before do
    @module = Module.new do
      def self.name
        'MissDaisy'
      end
    end
    @module.extend Rainman::Driver
    Object.send(:remove_const, :MissDaisy) if Object.const_defined?(:MissDaisy)
    Object.const_set(:MissDaisy, @module)
  end

  describe "::extended" do
    it "extends base with base" do
      m = Module.new
      m.should_receive(:extend).with(m)
      Rainman::Driver.extended(m)
    end
  end

  describe "#handlers" do
    it "returns an empty hash" do
      @module.handlers.should == {}
    end

    it "raises exception when accessing an unknown key" do
      expect { @module.handlers[:foo] }.to raise_error(Rainman::InvalidHandler)
    end
  end

  describe "#with_handler" do

  end

  describe "#set_default_handler" do
    it "sets @default_handler" do
      @module.set_default_handler :blah
      @module.instance_variable_get(:@default_handler).should == :blah
    end
  end

  describe "#default_handler" do
    it "gets @default_handler" do
      expected = @module.instance_variable_get(:@default_handler)
      @module.default_handler.should eq(expected)
    end
  end

  describe "HandlerMethods" do
    before do
      @class = Class.new do
        extend Rainman::Driver::HandlerMethods
      end
      @class.instance_variable_set(:@handler_name, :blah)
    end

    describe "#config" do
      it "returns Configuration[handler_name]" do
        @class.config.should eq Rainman::Driver::Configuration[:blah]
      end
    end

    describe "#validations" do
      it "returns Validations[handler_name]" do
        @class.validations.should eq Rainman::Driver::Validations[:blah]
      end
    end

    describe "#handler_name" do
      it "returns @handler_name" do
        @class.handler_name.should == :blah
        @class.handler_name.should eq @class.instance_variable_get(:@handler_name)
      end
    end
  end

  describe "#included" do
    it "extends base with Forwardable" do
      klass = Class.new
      klass.should_receive(:extend).with(::Forwardable)
      klass.stub(:def_delegators)
      klass.send(:include, @module)
    end

    it "sets up delegation for singleton methods" do
      klass = Class.new
      klass.should_receive(:def_delegators).with(@module, *@module.singleton_methods)
      klass.send(:include, @module)
    end
  end

  describe "#handler_instances" do
    it "returns @handler_instances" do
      @module.send(:handler_instances).should == {}
      @module.instance_variable_set(:@handler_instances, { :foo => :test })
      @module.send(:handler_instances).should == { :foo => :test }
    end
  end

  describe "#set_current_handler" do
    it "sets @current_handler" do
      @module.send(:set_current_handler, :blah)
      @module.instance_variable_get(:@current_handler).should == :blah
    end
  end

  describe "#current_handler_instance" do
    before do
      @class = Class.new
      @klass = @class.new
      @module.handlers[:abc] = @class
      @module.send(:set_current_handler, :abc)
    end

    it "returns the handler instance" do
      @module.send(:handler_instances).merge!(abc: @klass)
      @module.send(:current_handler_instance).should == @klass
    end

    it "sets the handler instance" do
      @module.handlers[:abc] = @class
      @class.should_receive(:new).and_return(@klass)
      @module.send(:current_handler_instance).should be_a(@class)
    end
  end

  describe "#current_handler" do
    it "returns @current_handler if set" do
      @module.instance_variable_set(:@current_handler, :blah)
      @module.send(:current_handler).should == :blah
    end

    it "returns @default_handler if @current_handler is not set" do
      @module.instance_variable_set(:@current_handler, nil)
      @module.instance_variable_set(:@default_handler, :blah)
      @module.send(:current_handler).should == :blah
    end
  end

  describe "#register_handler" do
    before do
      @bob = Class.new do
        def self.name; 'Bob'; end
      end
      @module.const_set(:Bob, @bob)
    end

    it "adds the handler to handlers" do
      @module.send(:register_handler, :bob)
      @module.handlers.should have_key(:bob)
      @module.handlers[:bob].should == @bob
    end

    it "extends handler with handler methods" do
      @bob.should_receive(:extend).with(Rainman::Driver::HandlerMethods)
      @bob.stub(:config).and_return({})
      @module.send(:register_handler, :bob)
    end
  end

  describe "#define_action" do
    it "does something with the block"

    it "creates the method" do
      @module.should_not respond_to(:blah)
      @module.send(:define_action, :blah)
      @module.should respond_to(:blah)

      klass = Class.new.new
      @module.stub(:current_handler_instance).and_return(klass)
      runner = Rainman::Driver::Runner.new(klass)
      Rainman::Driver::Runner.should_receive(:new).with(klass).and_return(runner)
      runner.should_receive(:send)

      @module.blah
    end
  end

  describe "#create_method" do
    it "raises AlreadyImplemented if the method has been defined" do
      @module.instance_eval do
        def blah; end
      end

      expect do
        @module.send(:create_method, :blah)
      end.to raise_error(Rainman::AlreadyImplemented)
    end

    it "adds the method" do
      @module.should_not respond_to(:blah)
      @module.send(:create_method, :blah, lambda { :hi })
      @module.should respond_to(:blah)
      @module.blah.should == :hi
    end
  end
end
