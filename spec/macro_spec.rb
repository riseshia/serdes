# frozen_string_literal: true

RSpec.describe "Macro" do
  class MacroDatabase
    include Serdes

    rename_all_attributes :PascalCase

    attribute :user_name, String
  end

  describe "deserialize" do
    let(:database_hash) do
      {
        "UserName" => "mysql"
      }
    end

    it "does not raise error" do
      expect {
        MacroDatabase.from(database_hash)
      }.not_to raise_error
    end

    it "deserialize correct" do
      database = MacroDatabase.from(database_hash)
      expect(database.user_name).to eq("mysql")
    end
  end

  describe "serialize" do
    let(:database) do
      MacroDatabase.new.tap do |database|
        database.user_name = "mysql"
      end
    end

    it "serialize to hash correct" do
      expect(database.to_hash).to eq({ "UserName" => "mysql" })
    end
  end
end
