require 'spec_helper'

describe "NestedAttribute behavior" do
  before do
    class Bar < ActiveFedora::Base
      belongs_to :car, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
      has_metadata type: ActiveFedora::SimpleDatastream, name: "someData" do |m|
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
      accepts_nested_attributes_for :bars, allow_destroy: true
    end

    # class used in test for reject_if: :all_blank
    class CarAllBlank < Car
      accepts_nested_attributes_for :bars, reject_if: :all_blank
    end

    # class used in test for reject_if: with proc object
    class CarProc < Car
      accepts_nested_attributes_for :bars, reject_if: proc { |attributes| attributes['uno'].blank? }
    end

    # class used in test for reject_if: with method name as symbol
    class CarSymbol < Car
      accepts_nested_attributes_for :bars, reject_if: :uno_blank

      def uno_blank(attributes)
        attributes['uno'].blank?
      end
    end

    # class used in test for :limit
    class CarWithLimit < Car
      accepts_nested_attributes_for :bars, limit: 1
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

  let(:car_class) { Car }
  let(:bar_class) { Bar }
  let(:car_no_bars) { car_class.create }
  let(:car_with_bars) { bar1; bar2; car_no_bars }
  let(:car) { car_with_bars }
  let(:bar1) { bar_class.create(car: car_no_bars) }
  let(:bar2) { bar_class.create(car: car_no_bars) }


  it "should have _destroy" do
    expect(Bar.new._destroy).to be_nil
  end

  it "should update the child objects" do
    car.update bars_attributes: [{id: bar1.id, uno: "bar1 uno"}, {uno: "newbar uno"}, {id: bar2.id, _destroy: '1', uno: 'bar2 uno'}]
    expect(Bar.find(bar1.id).uno).to eq 'bar1 uno'
    expect(Bar.where(id: bar2.id).first).to be_nil
    expect(Bar.where(uno: "newbar uno").first).to_not be_nil

    bars = car.bars(true)
    expect(bars).to include(bar1)
    expect(bars).to_not include(bar2)
  end

  describe "reject_if: :all_blank" do
    let(:car_class) { CarAllBlank }
    it "should reject attributes when all blank" do
      expect(car.bars.count).to eq 2
      car.update bars_attributes: [{}, {id: bar1.id, uno: "bar1 uno"}]
      expect(car.bars(true).count).to eq 2

      bar1.reload
      expect(bar1.uno).to eq "bar1 uno"
    end
  end

  describe "reject_if: with a proc" do
    let(:car_class) { CarProc }
    it "should reject attributes based on proc" do
      car.update bars_attributes: [{}, {id: bar1.id, uno: "bar1 uno"}, {id: bar2.id, dos: "bar2 dos"}]
      bar1.reload
      bar2.reload
      expect(bar1.uno).to eq "bar1 uno"
      expect(bar2.dos).to be_nil
    end
  end

  describe "allow_destroy: false" do
    let(:car_class) { CarProc }
    it "should create a new record even if _destroy is set" do
      expect(car.bars.count).to eq 2
      car.update bars_attributes: [{uno: "new uno", _destroy: "1"}]
      expect(car.bars(true).count).to eq 3
    end
  end

  describe "reject_if: with a symbol" do
    let(:car_class) { CarSymbol }
    it "should reject attributes base on method name" do
      car.update bars_attributes: [{}, {id: bar1.id, uno: "bar1 uno"}, {id: bar2.id, dos: "bar2 dos"}]
      bar1.reload
      bar2.reload
      expect(bar1.uno).to eq "bar1 uno"
      expect(bar2.dos).to be_nil
    end
  end

  describe "limit" do
    let(:car_class) { CarWithLimit }
    it "should throw TooManyRecords" do
      expect {
        car.attributes = {bars_attributes: [{}]}
      }.to_not raise_exception

      expect {
        car.attributes = {bars_attributes: [{}, {}]}
      }.to raise_exception(ActiveFedora::NestedAttributes::TooManyRecords)
    end
  end
end
