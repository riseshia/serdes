# Serdes

Serdes is a tool for *ser*ializing and *des*erializing class.
It provides:

- general way to serialize and deserialize
- simple type checking for attributes
- basic implementation for some class to Hash.

## Installation

```bash
bundle add serdes
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install serdes
```

## Usage

```ruby
require "serdes"

class User
  include Serdes

  rename_all_attributes :PascalCase

  attribute :name, String
  attribute :age, Integer
  attribute :profile, optional(String)
  attribute :tags, array(String)
  attribute :has_pet, Boolean
  attribute :plan, String, only: ["free", "premium"]
end

user_hash = {
  "Name" => "Alice",
  "Age" => 20,
  "HasPet" => true,
  "Tags" => ["tag1", "tag2"]
}

user = User.from(user_hash)

user_hash = {
  "Name" => "Alice",
  "Age" => 20,
  "HasPet" => true,
  "Tags" => ["tag1", "tag2"]
}

User.from(user_hash) # => raise Serdes::TypeError
```

### API

- `<class>.from(obj)`: Deserialize object to <class> instance.
  - `from` will call `from_<obj.class>` method if it exists. if not, it returns obj as it is.
- `<class>#to_hash`: Serialize <class> instance to Hash.
  - There is no support for serialization, as only you need to do is just implement `to_<class>` method where you want.

### Types

`serdes` provides some convenient types for type checking:

- `optional(type)`:  `type` | `nil`
- `array`: Array of `type`

### Macro

#### Global macro

- `rename_all_attributes`: Rename all attributes when serializing and deserializing.
  - Supported: `:snake_case`, `:PascalCase`
- `symbolize_all_keys`: Symbolize all keys when serializing and deserializing Hash, and vice versa.

#### Attribute macro

You can also use macro for each attribute by specifying 3rd argument of `attribute`.

- `only`: Only allow given values.
- `skip_serializing`: Skip serializing attribute by setting truthy value. it will ignore `skip_serializing_if`, `skip_serializing_if_nil` when this set.
- `skip_serializing_if`: Skip serializing if given proc call returns true.
- `skip_serializing_if_nil`: alias of `skip_serializing_if: ->(v) { v.nil? }`. It will ignore `skip_serializing_if` when this set.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/riseshia/serdes.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
