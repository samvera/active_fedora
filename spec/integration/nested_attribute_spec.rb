require 'spec_helper'

describe "NestedAttribute behavior" do
  before do
    class Bar < ActiveFedora::Base
      belongs_to :car, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
      has_metadata :type=>ActiveFedora::SimpleDatastream, :name=>"someData" do |m|
        m.field "uno", :string
        m.field "dos", :string
      end
      Deprecation.silence(ActiveFedora::Attributes) do
        has_attributes :uno, :dos, datastream: 'someData', multiple: false
      end
    end

    # base Car class, used in test for association updates and :allow_destroy flag
    class Car < ActiveFedora::Base
      has_many :bars, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
      accepts_nested_attributes_for :bars, :allow_destroy=>true
    end

    # class used in test for :reject_if=>:all_blank
    class CarAllBlank < Car
      accepts_nested_attributes_for :bars, :reject_if=>:all_blank
    end

    # class used in test for :reject_if with proc object
    class CarProc < Car
      accepts_nested_attributes_for :bars, :reject_if=>proc { |attributes| attributes['uno'].blank? }
    end

    # class used in test for :reject_if with method name as symbol
    class CarSymbol < Car
      accepts_nested_attributes_for :bars, :reject_if=>:uno_blank

      def uno_blank(attributes)
        attributes['uno'].blank?
      end
    end

    # class used in test for :limit
    class CarWithLimit < Car
      accepts_nested_attributes_for :bars, :limit => 1
    end
  end
  after do
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :CarAllBlank)
    Object.send(:remove_const, :CarProc)
    Object.send(:remove_const, :CarSymbol)
    Object.send(:remove_const, :CarWithLimit)
    Object.send(:remove_const, :Car)
  end

  it "should have _destroy" do
    expect(Bar.new._destroy).to be_nil
  end

  it "should update the child objects" do
    @car, @bar1, @bar2 = create_car_with_bars

    @car.update bars_attributes: [{id: @bar1.id, uno: "bar1 uno"}, {uno: "newbar uno"}, {id: @bar2.id, _destroy: '1', uno: 'bar2 uno'}]
    expect(Bar.find(@bar1.id).uno).to eq 'bar1 uno'
    expect(Bar.where(:id => @bar2.id).first).to be_nil
    expect(Bar.where(:uno => "newbar uno").first).to_not be_nil

    bars = @car.bars(true)
    expect(bars).to include(@bar1)
    expect(bars).to_not include(@bar2)
  end

  it "should reject attributes when all blank" do
    @car, @bar1, @bar2 = create_car_with_bars(CarAllBlank)

    expect(@car.bars.count).to eq 2
    @car.update bars_attributes: [{}, {:id=>@bar1.id, :uno=>"bar1 uno"}]
    expect(@car.bars(true).count).to eq 2

    @bar1.reload
    expect(@bar1.uno).to eq "bar1 uno"
  end

  it "should reject attributes based on proc" do
    @car, @bar1, @bar2 = create_car_with_bars(CarProc)

    @car.update bars_attributes: [{}, {:id=>@bar1.id, :uno=>"bar1 uno"}, {:id=>@bar2.id, :dos=>"bar2 dos"}]
    @bar1.reload
    @bar2.reload
    expect(@bar1.uno).to eq "bar1 uno"
    expect(@bar2.dos).to be_nil
  end

  it "should reject attributes base on method name" do
    @car, @bar1, @bar2 = create_car_with_bars(CarSymbol)

    @car.update bars_attributes: [{}, {:id=>@bar1.id, :uno=>"bar1 uno"}, {:id=>@bar2.id, :dos=>"bar2 dos"}]
    @bar1.reload
    @bar2.reload
    expect(@bar1.uno).to eq "bar1 uno"
    expect(@bar2.dos).to be_nil
  end

  it "should throw TooManyRecords" do
    @car, @bar1, @bar2 = create_car_with_bars(CarWithLimit)

    expect {
      @car.attributes = {:bars_attributes=>[{}]}
    }.to_not raise_exception

    expect {
      @car.attributes = {:bars_attributes=>[{}, {}]}
    }.to raise_exception(ActiveFedora::NestedAttributes::TooManyRecords)
  end

  private

  # Helper method used to create 1 Car and 2 Bars (with option to provide classes for both models)
  #
  # @param car_class [class] class for new `car` object, default Car
  # @param bar_class [class] class for new `bar` object, default Bar
  #
  # @return [car,bar,bar] returns 1 Car and 2 Bars
  def create_car_with_bars(car_class = Car, bar_class = Bar)
    car = car_class.new; car.save!

    bar1 = bar_class.new(car: car); bar1.save!
    bar2 = bar_class.new(car: car); bar2.save!
    [car, bar1, bar2]
  end

end
