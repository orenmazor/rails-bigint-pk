## rails-bigint-pk [![Build Status](https://secure.travis-ci.org/Shopify/rails-bigint-pk.png?branch=master)](https://travis-ci.org/Shopify/rails-bigint-pk)

### Overview

rails-bigint-pk aims to be a simple, transparent way to use 64bit primary keys
in mysql and postgres.

### Installation & Usage

* Add the following to your `Gemfile`
  `gem 'rails-bigint-pk', git: 'https://github.com/Shopify/rails-bigint-pk.git'`

### Gotchas

When adding foreign key columns, be sure to use `references` and not
`add_column`.

```ruby
change_table :my_table do |t|
  t.references :other_table
end

# Doing this will not use 64bit ints
add_column :my_table, :other_table_id, :int
```
