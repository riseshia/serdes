# frozen_string_literal: true

RSpec.describe "Deserialize" do
  class Database
    include Serdes

    attribute :adapter, String, only: %w[mysql postgresql]
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

  describe "deserialize" do
    context "simple case" do
      let(:database_hash) do
        {
          "adapter" => "mysql",
          "some_flag" => true,
        }
      end

      it "does not raise error" do
        expect {
          Database.from(database_hash)
        }.not_to raise_error
      end

      it "deserialize correct" do
        database = Database.from(database_hash)
        expect(database.adapter).to eq("mysql")
        expect(database.some_flag).to be true
      end

      it "raises error" do
        expect {
          Database.from(database_hash.merge("adapter" => 1))
        }.to raise_error(Serdes::TypeError, "Wrong type for Database#adapter. Expected type String, got Integer (val: '1').")
      end

      it "raises error by only" do
        expect {
          Database.from(database_hash.merge("adapter" => "sqlite3"))
        }.to raise_error(Serdes::TypeError, %q|Wrong value for Database#adapter. Expected value is ["mysql", "postgresql"], got 'sqlite3'.|)
      end
    end

    context "optional case" do
      context "when attribute exists" do
        let(:table_hash) do
          {
            "name" => "users",
            "comment" => "This is a comment",
          }
        end

        it "does not raise error" do
          expect {
            Table.from(table_hash)
          }.not_to raise_error
        end

        it "deserialize correct" do
          table = Table.from(table_hash)
          expect(table.name).to eq("users")
          expect(table.comment).to eq("This is a comment")
        end

        it "raises error" do
          expect {
            Table.from(table_hash.merge("comment" => 1))
          }.to raise_error(Serdes::TypeError)
        end
      end

      context "when attribute is missed" do
        let(:table_hash) do
          {
            "name" => "users",
          }
        end

        it "deserialize correct" do
          expect {
            Table.from(table_hash)
          }.not_to raise_error
        end

        it "does not raise error" do
          table = Table.from(table_hash)
          expect(table.name).to eq("users")
          expect(table.comment).to be_nil
        end
      end
    end

    context "array case" do
      let(:config_hash) do
        {
          "table_names" => ["users", "posts"]
        }
      end

      it "does not raise error" do
        expect {
          Config.from(config_hash)
        }.not_to raise_error
      end

      it "deserialize correct" do
        config = Config.from(config_hash)
        expect(config.table_names).to eq(["users", "posts"])
      end

      it "raises error" do
        expect {
          Config.from(config_hash.merge("table_names" => ["users", 1]))
        }.to raise_error(Serdes::TypeError, %q|Wrong type for Config#table_names. Expected type array(String), got Array (val: '["users", 1]').|)
      end
    end

    context "array in optional" do
      context "when attribute exists" do
        let(:nested_tags_hash) do
          {
            "tags" => ["tag1", "tag2"]
          }
        end

        it "does not raise error" do
          expect {
            NestedTags.from(nested_tags_hash)
          }.not_to raise_error
        end

        it "deserialize correct" do
          nested_tags = NestedTags.from(nested_tags_hash)
          expect(nested_tags.tags).to eq(["tag1", "tag2"])
        end

        it "raises error" do
          expect {
            NestedTags.from({ "tags" => "some_tag" })
          }.to raise_error(Serdes::TypeError)

          expect {
            NestedTags.from({ "tags" => [1, 2] })
          }.to raise_error(Serdes::TypeError, %q|Wrong type for NestedTags#tags. Expected type optional(array(String)), got Array (val: '[1, 2]').|)
        end
      end

      context "when attribute is missed" do
        let(:nested_tags_hash) do
          {}
        end

        it "does not raise error" do
          expect {
            NestedTags.from(nested_tags_hash)
          }.not_to raise_error
        end

        it "deserialize correct" do
          nested_tags = NestedTags.from(nested_tags_hash)
          expect(nested_tags.tags).to be_nil
        end
      end
    end

    context "optional in array" do
      context "when attribute exists" do
        let(:optional_array_hash) do
          {
            "tags" => ["tag1", nil]
          }
        end

        it "does not raise error" do
          expect {
            OptionalArray.from(optional_array_hash)
          }.not_to raise_error
        end

        it "deserialize correct" do
          optional_array = OptionalArray.from(optional_array_hash)
          expect(optional_array.tags).to eq(["tag1", nil])
        end

        it "raises error" do
          expect {
            OptionalArray.from({ "tags" => "some_tag" })
          }.to raise_error(Serdes::TypeError)

          expect {
            OptionalArray.from({ "tags" => ["string", 2] })
          }.to raise_error(Serdes::TypeError)
        end
      end

      context "when attribute is missed" do
        let(:optional_array_hash) do
          { "tags" => [nil] }
        end

        it "does not raise error" do
          expect {
            OptionalArray.from(optional_array_hash)
          }.not_to raise_error
        end

        it "deserialize correct" do
          optional_array = OptionalArray.from(optional_array_hash)
          expect(optional_array.tags).to eq([nil])
        end
      end
    end
  end
end
