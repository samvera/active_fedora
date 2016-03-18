require 'spec_helper'

describe "NestedAttribute behavior" do
  before do
    class Bar < ActiveFedora::Base
      belongs_to :car, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
      property :uno, predicate: ::RDF::URI('http://example.com/uno'), multiple: false
      property :dos, predicate: ::RDF::URI('http://example.com/dos'), multiple: false
    end

    # base Car class, used in test for association updates and :allow_destroy flag
    class Car < ActiveFedora::Base
      has_many :bars, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
      accepts_nested_attributes_for :bars, allow_destroy: true
    end
  end
  after do
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :Car)
  end

  let(:car_class) { Car }
  let(:car) { car_class.create }
  let(:bar1) { Bar.create(car: car) }
  let(:bar2) { Bar.create(car: car) }

  it "has _destroy" do
    expect(Bar.new._destroy).to be_nil
  end

  it "updates the child objects" do
    car.update bars_attributes: [{ id: bar1.id, uno: "bar1 uno" }, { uno: "newbar uno" }, { id: bar2.id, _destroy: '1', uno: 'bar2 uno' }]
    expect(Bar.all.map(&:uno)).to match_array ['bar1 uno', 'newbar uno']

    bars = car.bars(true)
    expect(bars).to include(bar1)
    expect(bars).to_not include(bar2)
  end

  context "when reject_if: :all_blank" do
    before do
      class CarAllBlank < Car
        accepts_nested_attributes_for :bars, reject_if: :all_blank
      end
    end

    let(:car_class) { CarAllBlank }
    after { Object.send(:remove_const, :CarAllBlank) }
    let(:car) { car_class.create }
    let!(:bar1) { Bar.create(car: car) }
    let!(:bar2) { Bar.create(car: car) }

    it "rejects attributes when all blank" do
      expect(car.bars.count).to eq 2
      car.update bars_attributes: [{}, { id: bar1.id, uno: "bar1 uno" }]
      expect(car.bars(true).count).to eq 2

      bar1.reload
      expect(bar1.uno).to eq "bar1 uno"
    end
  end

  context "when reject_if attribute is supplied with a proc" do
    before do
      class CarProc < Car
        accepts_nested_attributes_for :bars, reject_if: ->(attributes) { attributes['uno'].blank? }
      end
    end

    after { Object.send(:remove_const, :CarProc) }
    let(:car_class) { CarProc }

    context "and the reject_if proc evaluates to false" do
      before do
        car.update bars_attributes: [{}, { id: bar1.id, uno: "bar1 uno" }]
      end
      it "updates attributes" do
        expect(bar1.reload.uno).to eq "bar1 uno"
      end
    end

    context "and the reject_if proc evaluates to true" do
      before do
        car.update bars_attributes: [{}, { id: bar1.id, dos: "bar1 uno" }]
      end
      it "rejects attributes" do
        expect(bar1.reload.dos).to be_nil
      end
    end

    context "and `allow_destroy: false`" do
      context "and the reject_if proc evaluates to true" do
        before do
          car.update bars_attributes: [{}, { id: bar1.id, dos: "bar1 uno", _destroy: "1" }]
        end
        it "rejects attributes (_destroy doesn't affect the outcome)" do
          expect(bar1.reload.dos).to be_nil
        end
      end

      context "a record with the destroy flag and without an id" do
        it "creates a new record" do
          expect {
            car.update bars_attributes: [{ uno: "bar1 uno", _destroy: "1" }]
          }.to change { car.bars(true).count }.by(1)
        end

        it "does not create a new record if reject_if conditions are triggered" do
          expect {
            car.update bars_attributes: [{ uno: "", _destroy: "1" }]
          }.not_to change { car.bars(true).count }
        end
      end
    end
  end

  describe "reject_if: with a symbol" do
    before do
      # class used in test for reject_if: with method name as symbol
      class CarSymbol < Car
        accepts_nested_attributes_for :bars, reject_if: :uno_blank

        def uno_blank(attributes)
          attributes['uno'].blank?
        end
      end
    end

    after { Object.send(:remove_const, :CarSymbol) }
    let(:car_class) { CarSymbol }

    it "rejects attributes based on method name" do
      car.update bars_attributes: [{}, { id: bar1.id, uno: "bar1 uno" }, { id: bar2.id, dos: "bar2 dos" }]
      bar1.reload
      bar2.reload
      expect(bar1.uno).to eq "bar1 uno"
      expect(bar2.dos).to be_nil
    end
  end

  describe "allow_destroy: true" do
    before do
      class CarDestroy < Car
        accepts_nested_attributes_for :bars, allow_destroy: true
      end
    end

    let(:car_class) { CarDestroy }
    after { Object.send(:remove_const, :CarDestroy) }

    it "doesn't create a new record if _destroy is set" do
      expect {
        car.update bars_attributes: [{ uno: "new uno", _destroy: "1" }]
      }.not_to change { car.bars(true).count }
    end
  end

  describe "limit" do
    before do
      class CarWithLimit < Car
        accepts_nested_attributes_for :bars, limit: 1
      end
    end
    after { Object.send(:remove_const, :CarWithLimit) }

    let(:car_class) { CarWithLimit }
    it "throws TooManyRecords" do
      expect {
        car.attributes = { bars_attributes: [{}] }
      }.to_not raise_exception

      expect {
        car.attributes = { bars_attributes: [{}, {}] }
      }.to raise_exception(ActiveFedora::NestedAttributes::TooManyRecords)
    end
  end
end
