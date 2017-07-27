require 'bigint_pk/version'
require 'bigint_pk/railtie'
require 'active_record'

module BigintPk
  extend self

  def enable!(adapter)
    install_patches!(adapter)
  end

  private

  module PostgresBigintPrimaryKey
    def primary_key(name, type = :primary_key, **options)
      if type == :primary_key
        super(name, :bigserial, **options)
      else
        super
      end
    end
  end

  module MysqlBigintPrimaryKey
    def primary_key(name, type = :primary_key, **options)
      if type == :primary_key
        options[:auto_increment] = true unless options.key?(:default)
        super(name, ActiveRecord::VERSION::MAJOR < 5 ? :primary_key : :bigint, **options)
      else
        super
      end
    end
  end

  module DefaultBigintForeignKeyReferences
    def references(*args)
      options = args.extract_options!
      options.reverse_merge! limit: 8
      # Limit shouldn't affect "#{col}_type" column in polymorphic reference.
      # But don't change value if it isn't simple 'true'.
      # Examples:
      #   t.references :subject, null: false, polymorphic: true ==> t.integer :subject_id, limit: 8, null: false
      #                                                             t.string  :subject_type, null: false
      #   t.references :subject, polymorphic: { limit: 120 }    ==> t.integer :subject_id, limit: 8
      #                                                             t.string  :subject_type, limit: 120
      options[:polymorphic] = options.except(:polymorphic, :limit) if options[:polymorphic] == true
      super(*args, options)
    end
  end

  def install_patches!(adapter)
    ca = ActiveRecord::ConnectionAdapters

    case adapter
    when 'postgresql'
      pk_module = PostgresBigintPrimaryKey
      require 'active_record/connection_adapters/postgresql_adapter'
      ca::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigserial primary key'
    when /mysql\d+/
      pk_module = MysqlBigintPrimaryKey
      require 'active_record/connection_adapters/abstract_mysql_adapter'
      ca::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigint(20) auto_increment PRIMARY KEY'
      ca::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:integer] = { :name => "bigint", :limit => 6 }
    else
      raise "Only MySQL and PostgreSQL adapters are supported now. Tried to patch #{adapter}."
    end

    [ca::TableDefinition,
     ca::Table].each do |abstract_table_type|
      abstract_table_type.prepend(pk_module)
      abstract_table_type.prepend(DefaultBigintForeignKeyReferences)
    end
  end
end
