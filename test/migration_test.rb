require 'minitest/autorun'
require 'bigint_pk'

BigintPk.enable!(ENV['ADAPTER'] || "mysql2")

class MigrationTest < Minitest::Test
  def setup
    super
    ActiveRecord::Base.establish_connection(adapter: ENV['ADAPTER'] || "mysql2", database: "bigint_test")
  end

  def teardown
    super
    ActiveRecord::Base.connection.drop_table("foo") rescue nil
  end

  def test_creating_a_table_use_bigint_as_primary_key
    connection = ActiveRecord::Base.connection
    connection.create_table('foo')
    columns = connection.columns(:foo)
    assert_equal ['id'], columns.map(&:name)
    assert_equal [:integer], columns.map(&:type)
    if ENV['ADAPTER'] == 'postgresql'
      assert_equal ['bigint'], columns.map(&:sql_type)
      assert_equal ["nextval('foo_id_seq'::regclass)"], columns.map(&:default_function)
    else
      assert_equal ['bigint(20)'], columns.map(&:sql_type)
      assert_equal ['auto_increment'], columns.map(&:extra)
    end
    assert_equal [8], columns.map(&:limit)
  end

  def test_creating_a_reference_column_uses_bigint
    connection = ActiveRecord::Base.connection
    connection.create_table('foo') do |td|
      td.references :post
    end
    columns = connection.columns(:foo)
    assert_equal ['id', 'post_id'], columns.map(&:name)
    assert_equal [:integer, :integer], columns.map(&:type)
    if ENV['ADAPTER'] == 'postgresql'
      assert_equal ['bigint', 'bigint'], columns.map(&:sql_type)
    else
      assert_equal ['bigint(20)', 'bigint(20)'], columns.map(&:sql_type)
    end
    assert_equal [8, 8], columns.map(&:limit)
  end
end
