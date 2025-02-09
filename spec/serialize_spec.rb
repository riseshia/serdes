# frozen_string_literal: true

RSpec.describe "Serialize" do
  class Database
    include Serdes

    attribute :adapter, String
    attribute :some_flag, Boolean
  end

  class Table
    include Serdes

    attribute :name, String
    attribute :comment, optional(String)
  end

  class Config
    include Serdes

    attribute :table_names, array(String)
  end

  class NestedTags
    include Serdes

    attribute :tags, optional(array(String))
  end

  class OptionalArray
    include Serdes

    attribute :tags, array(optional(String))
  end

  describe "serialize" do
    context "simple case" do
      let(:database) do
        Database.new.tap do |database|
          database.adapter = "mysql"
          database.some_flag = true
        end
      end

      it "serialize to hash correct" do
        expect(database.to_hash).to eq({ "adapter" => "mysql", "some_flag" => true })
      end
    end

    context "optional case" do
      context "when attribute exists" do
        let(:table) do
          Table.new.tap do |table|
            table.name = "users"
            table.comment = "This is a comment"
          end
        end

        it "serialize to hash correct" do
          expect(table.to_hash).to eq({
            "name" => "users",
            "comment" => "This is a comment",
          })
        end
      end

      context "when attribute is missed" do
        let(:table) do
          Table.new.tap do |table|
            table.name = "users"
          end
        end

        it "serialize to hash correct" do
          expect(table.to_hash).to eq({
            "name" => "users",
            "comment" => nil,
          })
        end
      end
    end

    context "array case" do
      let(:config) do
        Config.new.tap do |config|
          config.table_names = ["users", "posts"]
        end
      end

      it "serialize to hash correct" do
        expect(config.to_hash).to eq({
          "table_names" => ["users", "posts"],
        })
      end
    end
  end
end
