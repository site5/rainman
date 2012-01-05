require 'spec_helper'

describe Rainman::Stash do
  subject { Rainman::Stash.new(:food => 'pizza') }

  it "returns @hash with #to_hash" do
    subject.to_hash.should eq(subject.instance_variable_get(:@hash))
  end

  it "allows assignment at initialization" do
    subject.to_hash.should == { :food => 'pizza' }
  end

  it "allows assignment of arbitrary variables" do
    subject.likes_to_eat :pizza
    subject.to_hash.should have_key(:likes_to_eat)
    subject.to_hash[:likes_to_eat].should == :pizza
  end

  it "allows retrieval of variables" do
    expect { subject.food }.to_not raise_error
    subject.food.should == 'pizza'
  end

  it "assigns multiple arguments" do
    subject.foods :pizza, :spaghetti
    subject.foods.should == [:pizza, :spaghetti]
  end

  it "deletes value from @hash when assigned to nil" do
    subject.foods nil
    subject.foods.should be_nil
    subject.to_hash.should_not have_key(:foods)
  end

  it "raises NameError when assigning with =" do
    expect { subject.favorites = :pizza }.to raise_error(NameError)
  end

  describe "assignment via []= and lookup via []" do
    it "assigns and returns a single value" do
      subject[:beverage] = :coke
      subject.to_hash.should have_key(:beverage)
      subject.beverage.should == :coke
      subject[:beverage].should eq(subject.beverage)
    end

    # special test case for 1.8.7, String#[] in 1.8.7 returns a character
    # code, so we need to account for that
    it "assigns a single character string" do
      subject[:straw] = 'N'
      subject.to_hash.should have_key(:straw)
      subject.straw.should == 'N'
      subject[:straw].should eq(subject.straw)
    end

    it "assigns an array of elements" do
      subject[:lunch] = :cheeseburger, :fries
      subject.to_hash.should have_key(:lunch)
      subject.lunch.should == [:cheeseburger, :fries]
      subject[:lunch].should eq(subject.lunch)

      subject[:initials] = 'J', 'S', 'P'
      subject.to_hash.should have_key(:initials)
      subject.initials.should == %W(J S P)
      subject[:initials].should eq(subject.initials)

      subject[:lucky_numbers] = [1, 2, 3]
      subject.to_hash.should have_key(:lucky_numbers)
      subject.lucky_numbers.should == [1, 2, 3]
      subject[:lucky_numbers].should eq(subject.lucky_numbers)
    end
  end

  it "allows lookup via []" do
    subject[:food].should == 'pizza'
  end

  it "returns the value when assigning a single value" do
    ret = subject.toppings :cheese
    ret.should == :cheese
  end

  it "returns the values when assigning multiple values" do
    ret = subject.toppings :cheese, :sausage
    ret.should == [:cheese, :sausage]
  end
end
