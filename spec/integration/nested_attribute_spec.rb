require 'spec_helper'

describe 'NestedAttribute behavior' do
  before do
    class Bar < ActiveFedora::Base
      belongs_to :car, :property => :has_member
      has_metadata :type => ActiveFedora::SimpleDatastream, :name => 'someData' do |m|
        m.field 'uno', :string
        m.field 'dos', :string
      end
      delegate :uno, to: 'someData', multiple: false
      delegate :dos, to: 'someData', multiple: false
    end

    # base Car class, used in test for association updates and :allow_destroy flag
    class Car < ActiveFedora::Base
      has_many :bars, :property => :has_member
      accepts_nested_attributes_for :bars, :allow_destroy => true
    end

    # class used in test for :reject_if=>:all_blank
    class CarAllBlank < Car
      accepts_nested_attributes_for :bars, :reject_if => :all_blank
    end

    # class used in test for :reject_if with proc object
    class CarProc < Car
      accepts_nested_attributes_for :bars, :reject_if => proc { |attributes| attributes['uno'].blank? }
    end

    # class used in test for :reject_if with method name as symbol
    class CarSymbol < Car
      accepts_nested_attributes_for :bars, :reject_if => :uno_blank

      def uno_blank(attributes)
        attributes['uno'].blank?
      end
    end

    # class used in test for :limit
    class CarWithLimit < Car
      accepts_nested_attributes_for :bars, :limit => 1
    end
  end

  it 'should have _destroy' do
    expect(Bar.new._destroy).to be_falsey
  end

  it 'should update the child objects' do
    @car, @bar1, @bar2 = create_car_with_bars

    @car.attributes = {:bars_attributes => [{:id => @bar1.pid, :uno => 'bar1 uno'}, {:uno => 'newbar uno'}, {:id => @bar2.pid, :_destroy => '1', :uno => 'bar2 uno'}]}
    expect(Bar.find(@bar1.pid).uno).to eq('bar1 uno')
    expect(Bar.where(:id => @bar2.pid).first).to be_nil
    expect(Bar.where(:uno => 'newbar uno').first).not_to be_nil

    bars = @car.bars(true)
    expect(bars).to include(@bar1)
    expect(bars).not_to include(@bar2)
  end

  it 'should reject attributes when all blank' do
    @car, @bar1, @bar2 = create_car_with_bars(CarAllBlank)

    expect(@car.bars.count).to eq(2)
    @car.attributes = {:bars_attributes => [{}, {:id => @bar1.pid, :uno => 'bar1 uno'}]}
    expect(@car.bars(true).count).to eq(2)

    @bar1.reload
    expect(@bar1.uno).to eq('bar1 uno')
  end

  it 'should reject attributes based on proc' do
    @car, @bar1, @bar2 = create_car_with_bars(CarProc)

    @car.attributes = {:bars_attributes => [{}, {:id => @bar1.pid, :uno => 'bar1 uno'}, {:id => @bar2.pid, :dos => 'bar2 dos'}]}
    @bar1.reload
    @bar2.reload
    expect(@bar1.uno).to eq('bar1 uno')
    expect(@bar2.dos).to be_nil
  end

  it 'should reject attributes base on method name' do
    @car, @bar1, @bar2 = create_car_with_bars(CarSymbol)

    @car.attributes = {:bars_attributes => [{}, {:id => @bar1.pid, :uno => 'bar1 uno'}, {:id => @bar2.pid, :dos => 'bar2 dos'}]}
    @bar1.reload
    @bar2.reload
    expect(@bar1.uno).to eq('bar1 uno')
    expect(@bar2.dos).to be_nil
  end

  it 'should throw TooManyRecords' do
    @car, @bar1, @bar2 = create_car_with_bars(CarWithLimit)

    expect {
      @car.attributes = {:bars_attributes => [{}]}
    }.not_to raise_exception

    expect {
      @car.attributes = {:bars_attributes => [{}, {}]}
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
    car = car_class.new; car.save

    bar1 = bar_class.new(:car => car); bar1.save
    bar2 = bar_class.new(:car => car); bar2.save
    [car, bar1, bar2]
  end

end
