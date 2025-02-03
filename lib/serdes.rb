# frozen_string_literal: true

require_relative "serdes/version"

module Serdes
  DeclareError = Class.new(StandardError)
  RequiredAttributeError = Class.new(StandardError)
  SerializeError = Class.new(StandardError)
  TypeError = Class.new(StandardError)
  AttributeAlreadyDefined = Class.new(StandardError)
  RenameStrategyNotFound = Class.new(StandardError)

  Boolean = [TrueClass, FalseClass].freeze

  class TypeBase
    def optional?
      false
    end

    def array?
      false
    end
  end

  class ConcreteType < TypeBase
    attr_reader :exact_type

    def initialize(exact_type)
      @exact_type = exact_type
    end

    def permit?(value)
      @exact_type == value.class
    end

    def to_s
      @exact_type.to_s
    end
  end

  class OptionalType < TypeBase
    attr_reader :base_type

    def initialize(base_type)
      @base_type = base_type
    end

    def optional?
      true
    end

    def permit?(value)
      return true if value.nil?

      if @base_type.is_a?(TypeBase)
        @base_type.permit?(value)
      else
        @base_type == value.class
      end
    end

    def to_s
      "optional(#{@base_type})"
    end
  end

  class ArrayType < TypeBase
    attr_reader :element_type

    def initialize(element_type)
      @element_type = element_type
    end

    def array?
      true
    end

    def permit?(value)
      return false if !value.is_a?(Array)

      if @element_type.is_a?(TypeBase)
        value.all? { |v| @element_type.permit?(v) }
      else
        value.all? { |v| v.class == @element_type }
      end
    end

    def to_s
      "array(#{@element_type})"
    end
  end

  class Attribute
    attr_accessor :class_name, :name, :attr_type, :options

    def initialize(class_name:, name:, attr_type:, options: {})
      @class_name = class_name
      @name = name
      @attr_type = attr_type
      @options = options
    end

    def serialized_name(rename_strategy = nil)
      if rename_strategy && rename_strategy != :snake_case
        Functions._serde_rename_strategy_func_fetch(:snake_case, rename_strategy).call(@name)
      else
        @name.to_s
      end
    end
  end

  def self.included(base)
    base.extend ClassMethods
    base.include InstanceMethods
  end

  module ClassMethods
    def optional(type)
      OptionalType.new(type)
    end

    def array(type)
      ArrayType.new(type)
    end

    def attribute(name, attr_type, options = {})
      attr_reader name

      attr_type = ConcreteType.new(attr_type) if !attr_type.is_a?(TypeBase)
      attr = Attribute.new(class_name: self.name, name: name, attr_type: attr_type, options: options)
      _serde_attrs[name] = attr
      _serde_deserialize_keymap[attr.serialized_name(_serde_rename_strategy)] = attr.name

      define_method("#{name}=") do |value|
        Functions.validate_type!(attr, value)
        instance_variable_set("@#{name}", value)
      end
    end

    def rename_all_attributes(strategy)
      if _serde_attrs.size.positive?
        raise AttributeAlreadyDefined, "Call rename_all_attributes before defining attributes."
      end

      rename_strategy =
        case strategy
        when :PascalCase
        when :snake_case
        else
          raise RenameStrategyNotFound, "Rename strategy '#{strategy}' not found."
        end

      @_serde_rename_strategy = strategy
    end

    def from(obj)
      Functions.from__proxy(self, obj)
    end

    def from_hash(hash)
      new.tap do |instance|
        _serde_attrs.each_value do |attr|
          key = attr.serialized_name(_serde_rename_strategy)
          serialized_value = hash[key]

          value = Functions.from__proxy(attr.attr_type, serialized_value)

          instance.__send__("#{attr.name}=", value)
        end
      end
    end

    private def _serde_attrs
      @_serde_attrs ||= {}
    end

    private def _serde_deserialize_keymap
      @_serde_deserialize_keymap ||= {}
    end

    private def _serde_rename_strategy
      @_serde_rename_strategy ||= :snake_case
    end
  end

  module InstanceMethods
    def to_hash
      self.class.__send__(:_serde_attrs).each_with_object({}) do |(name, attr), hash|
        key = attr.serialized_name(self.class.__send__(:_serde_rename_strategy))
        value = __send__(name)

        hash[key] =
          if value.respond_to?(:to_hash)
            value.to_hash
          elsif value.is_a?(Array)
            value.map { |v| Functions.skip_to_hash?(v) ? v : v.to_hash }
          elsif Functions.skip_to_hash?(value)
            value
          else
            raise SerializeError, "Cannot serialize #{attr.class_name}##{attr.name} to Hash."
          end
      end
    end
  end

  module Functions
    module_function

    # To avoid monkey patching stdlib classes, we use this proxy.
    def from__proxy(from_type, to_value)
      case from_type
      when OptionalType
        if to_value.nil?
          nil
        else
          from_type = from_type.base_type
          from__native_type__proxy(from_type, to_value)
        end
      when ArrayType
        if to_value.is_a?(Array)
          elem_type = from_type.element_type
          to_value.map { |v| from__native_type__proxy(elem_type, v) }
        else
          from__native_type__proxy(from_type, to_value)
        end
      when ConcreteType
        from_type = from_type.exact_type if from_type.is_a?(ConcreteType)
        from__native_type__proxy(from_type, to_value)
      else
        from__native_type__proxy(from_type, to_value)
      end
    end

    def from__native_type__proxy(from_type, to_value)
      from_method = Functions.from_interface_for(to_value)

      if from_type.respond_to?(from_method)
        from_type.__send__(from_method, to_value)
      else
        # Do nothing, delegate error to validate_type! for better error message if mismached.
        to_value
      end
    end

    def from_interface_for(obj)
      "from_#{const_name_to_snake_case(obj.class.name)}"
    end

    def const_name_to_snake_case(const_name)
      const_name.gsub(/A-Z/, "_\\1").downcase.gsub("::", "__")
    end

    def validate_type!(attr, value)
      valid = attr.attr_type.permit?(value)
      return if valid

      actual_type = humanize_type(value)

      raise TypeError, "Wrong type for #{attr.class_name}##{attr.name}. Expected type #{attr.attr_type}, got #{value.class} (val: '#{value}')."
    end

    def humanize_type(value)
      if value.is_a?(Array)
        "array(" + value.map { |el| humanize_type(el) }.join(", ") + ")"
      else
        case value
        when NilClass then "nil"
        when TrueClass then "boolean"
        when FalseClass then "boolean"
        else value.class.to_s
        end
      end
    end

    def skip_to_hash?(value)
      case value
      when NilClass, String, Numeric, TrueClass, FalseClass
        true
      else
        false
      end
    end

    def _serde_rename_strategy_func_fetch(from, to)
      _serde_rename_strategy_func[[from, to]]
    end

    def _serde_rename_strategy_func
      @_serde_rename_strategy_func ||= {
        [:PascalCase, :snake_case] => ->(name) { name.to_s.gsub(/([A-Z])/, '_\1').downcase },
        [:snake_case, :PascalCase] => ->(name) { name.to_s.split('_').map(&:capitalize).join },
      }
    end
  end
end
