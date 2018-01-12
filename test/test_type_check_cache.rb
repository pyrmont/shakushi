require 'test_helper'
require 'type_check'

class TypeCheckCacheTest < Minitest::Test
  context "TypeCheck:Cache" do
    setup do
      @Cache = TypeCheck::Cache
    end

    teardown do
      @Cache.reset
    end

    context "has a cache that" do
      setup do
        @value = Object.new
        @Cache['Test'] = @value
      end

      teardown do
        @Cache.reset
      end

      should "persist" do
        obj_1 = InstancedObject.new
        obj_2 = InstancedObject.new
        assert_equal @value, obj_1.get('Test')
        assert_equal @value, obj_2.get('Test')
      end

      should "reset" do
        obj = InstancedObject.new
        assert_equal @value, obj.get('Test')
        @Cache.reset
        refute_equal @value, obj.get('Test')
      end
    end

    context "has a class method .[] that" do
      should "retrieve an item from the cache" do
        value = Object.new
        @Cache['Test'] = value
        assert_equal value, @Cache['Test']
      end
    end

    context "has a class method .[]= that" do
      should "set the cache" do
        assert_nil @Cache['Test']
        @Cache['Test'] = Object.new
        refute_nil @Cache['Test']
      end
    end
  end

  class InstancedObject
    def get(key)
      TypeCheck::Cache[key]
    end
  end
end