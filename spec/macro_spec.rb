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
end
