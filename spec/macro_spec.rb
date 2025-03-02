# frozen_string_literal: true

RSpec.describe "Macro" do
  class PascalDatabase
    include Serdes

    rename_all_attributes :PascalCase

    attribute :user_name, String
  end

  class SymbolizedDatabase
    include Serdes

    symbolize_all_keys

    attribute :user_name, String
  end

  describe "rename_all_attributes" do
    describe "deserialize" do
      let(:database_hash) do
        {
          "UserName" => "mysql"
        }
      end

      it "does not raise error" do
        expect {
          PascalDatabase.from(database_hash)
        }.not_to raise_error
      end

      it "deserialize correct" do
        database = PascalDatabase.from(database_hash)
        expect(database.user_name).to eq("mysql")
      end
    end

    describe "serialize" do
      let(:database) do
        PascalDatabase.new.tap do |database|
          database.user_name = "mysql"
        end
      end

      it "serialize to hash correct" do
        expect(database.to_hash).to eq({ "UserName" => "mysql" })
      end
    end
  end

  describe "symbolized_all_keys" do
    describe "deserialize" do
      let(:database_hash) do
        {
          user_name: "mysql"
        }
      end

      it "does not raise error" do
        expect {
          SymbolizedDatabase.from(database_hash)
        }.not_to raise_error
      end

      it "deserialize correct" do
        database = SymbolizedDatabase.from(database_hash)
        expect(database.user_name).to eq("mysql")
      end
    end

    describe "serialize" do
      let(:database) do
        SymbolizedDatabase.new.tap do |database|
          database.user_name = "mysql"
        end
      end

      it "serialize to hash correct" do
        expect(database.to_hash).to eq({ user_name: "mysql" })
      end
    end
  end

  describe "skip_serializing" do
    describe "deserialize" do
      let(:database_hash) do
        {
          user_name: "mysql"
        }
      end

      it "does not raise error" do
        expect {
          SymbolizedDatabase.from(database_hash)
        }.not_to raise_error
      end

      it "deserialize correct" do
        database = SymbolizedDatabase.from(database_hash)
        expect(database.user_name).to eq("mysql")
      end
    end

    class SkipSerializingMacro
      include Serdes

      attribute :user_name, String
      attribute :tags, String, skip_serializing: true
    end

    describe "skip_serializing" do
      let(:obj) do
        SkipSerializingMacro.new.tap do |obj|
          obj.user_name = "mysql"
          obj.tags = "some_tags"
        end
      end

      it "serialize to hash correct" do
        expect(obj.to_hash).to eq({
          "user_name" => "mysql",
        })
      end
    end

    class SkipSerializingIfMacro
      include Serdes

      attribute :user_name, String
      attribute :filter, optional(String), skip_serializing_if: ->(v) { v.nil? }
    end

    describe "skip_serializing_if" do
      let(:filter) { nil }
      let(:obj) do
        SkipSerializingIfMacro.new.tap do |obj|
          obj.user_name = "mysql"
          obj.filter = filter
        end
      end

      context "filter is not nil" do
        let(:filter) { "some_filter" }

        it "serialize to hash correct" do
          expect(obj.to_hash).to eq({
            "user_name" => "mysql",
            "filter" => "some_filter",
          })
        end
      end

      context "filter is nil" do
        let(:filter) { nil }

        it "serialize to hash correct" do
          expect(obj.to_hash).to eq({
            "user_name" => "mysql",
          })
        end
      end
    end

    class SkipSerializingIfNilMacro
      include Serdes

      attribute :user_name, String
      attribute :filter, optional(String), skip_serializing_if_nil: true
    end

    describe "skip_serializing_if_nil" do
      let(:filter) { nil }
      let(:obj) do
        SkipSerializingIfNilMacro.new.tap do |obj|
          obj.user_name = "mysql"
          obj.filter = filter
        end
      end

      context "filter is not nil" do
        let(:filter) { "some_filter" }

        it "serialize to hash correct" do
          expect(obj.to_hash).to eq({
            "user_name" => "mysql",
            "filter" => "some_filter",
          })
        end
      end

      context "filter is nil" do
        let(:filter) { nil }

        it "serialize to hash correct" do
          expect(obj.to_hash).to eq({
            "user_name" => "mysql",
          })
        end
      end
    end
  end
end
