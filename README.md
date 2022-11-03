# Temping

[![Code Climate](https://codeclimate.com/github/jpignata/temping.png)](https://codeclimate.com/github/jpignata/temping)
[![Build Status](https://github.com/jpignata/temping/workflows/tests/badge.svg)](https://github.com/jpignata/temping/actions)
[![Gem Version](https://badge.fury.io/rb/temping.png)](http://badge.fury.io/rb/temping)

Temping allows you to create arbitrary ActiveRecord models backed by a temporary
SQL table for use in tests. You may need to do something like this if you're
testing a module that is meant to be mixed into ActiveRecord models without
relying on a concrete class.

Temping will use your existing database connection. As we're using temporary
tables all data will be dropped when the database connection is terminated.

## Examples

The basic setup of a model involves calling _create_ with a symbol that
represents the class name of the model you wish to create. By default,
this will create a temporary table with an _id_ column.

```ruby
Temping.create :dog

Dog.create => #<Dog id: 1>
Dog.table_name => "dogs"
Dog => Dog(id: integer)
```

Keep in mind, the table name will always be pluralized, while the class name will be singular.

```ruby
Temping.create :dogs

Dog.table_name => "dogs"
Dogs => NameError: uninitialized constant Dogs
```

Additional database columns can be specified via the _with_columns_ method
which uses Rails migration syntax:

```ruby
Temping.create :dog do
  with_columns do |t|
    t.string :name
    t.integer :age, :weight
  end
end

Dog.create

# => #<Dog id: 1, name: nil, age: nil, weight: nil>
```

When a block is passed to _create_, it is evaluated in the context of the class.
This means anything you do in an ActiveRecord model class body can be
accomplished in the block including method definitions, validations, module
includes, etc.

```ruby
Temping.create :dog do
  validates :name, presence: true

  with_columns do |t|
    t.string :name
    t.integer :age, :weight
  end

  def quack
    "arf!"
  end
end

Dog.create!

# => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank

codey = Dog.create! name: "Codey"
codey.quack

# => "arf!"
```

All attributes you can pass to `create_table` can be evaluated too. For example you can create a dog with a primary key of the type uuid:

```ruby
Temping.create :dog, id: :uuid, default: -> { 'uuid_generate_v4()' }

Dog.create

# => #<Dog id: d937951b-765c-4bc9-804e-3171d22117b0>
```

## Options

An option to specify the parent class can be given as a second parameter to `Temping.create`. This allows testing in environments where models inherit from a common base class.

```ruby
# A custom base model class
class Vehicle < ActiveRecord::Base
  self.abstract_class = true
  def navigate_to(destination)
    # non-vehicle specific logic
  end
end

Temping.create :car, parent_class: Vehicle do
  with_columns do |t|
    t.string :name
    t.integer :num_wheels
  end
end
Temping.create :bus, parent_class: Vehicle do
  with_columns do |t|
    t.string :name
    t.integer :num_wheels
  end
end

my_car = Car.create
my_car.navigate_to(:home)
```



## Installation

In your Gemfile:

```ruby
gem "temping"
```

In `test_helper.rb` add the following block to `ActiveSupport::TestCase`:

```ruby
class ActiveSupport::TestCase
  # ...
  teardown do
    Temping.teardown
  end
  # ...
end
```

Or, if you're using `rspec`, in `spec_helper.rb` add the following block to `RSpec.configure`:

```ruby
RSpec.configure do |config|
  # ...
  config.after do
    Temping.teardown
  end
  # ...
end
```

Alternatively you may want to just cleanup tables, but keep defined models:

```ruby
Temping.cleanup
```

## Support

The latest version of this gem is tested with the following interpreters/gems:

* MRI 3.2 with ActiveRecord 7.0
* MRI 3.1 with ActiveRecord 7.0, 6.1
* MRI 3.0 with ActiveRecord 7.0, 6.1
* MRI 2.7 with ActiveRecord 7.0, 6.1, 6.0
* MRI 2.6 with ActiveRecord 6.1, 6.0
* MRI 2.5 with ActiveRecord 6.1, 6.0
* MRI 2.4 with ActiveRecord 5.2
* JRuby with ActiveRecord 6.1, 6.0 (activerecord-jdbc-adapter)
* TruffleRuby with ActiveRecord 7.0, 6.1, 6.0

with the following database systems:

* SQLite3
* MySQL (versions 5.5-8.0)
* PostgreSQL (versions 10-15)

If you need to support older versions of ruby or ActiveRecord you might have to use
the older versions of this gem (3.10.0 or below).

## Bugs, Features, Feedback

All contributions are welcome! Please take a look at `CONTRIBUTING.md` for some
tips.
