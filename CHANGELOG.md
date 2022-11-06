# Changelog

User-visible changes worth mentioning.

---

## Unreleased
- [#79](https://github.com/jpignata/temping/pull/79): Support namespaces
- [#77](https://github.com/jpignata/temping/pull/77): Fix `.teardown` and `.cleanup` methods to process 
models in the reverse order  - Thanks @gregnavis
- [#59](https://github.com/jpignata/temping/pull/59): Add support for Ruby 3.0 and above - Thanks @dark-panda
- [#68](https://github.com/jpignata/temping/pull/68): Add support for Rails 7.0
- [#69](https://github.com/jpignata/temping/pull/69), 
[#81](https://github.com/jpignata/temping/pull/81): 
Drop support for Ruby below 2.2.2 and Rails below 5.2

## 3.10.0 - 2017-09-27
- Drop support for `mysql`, just test `mysql2`
- Drop support for Rails 3.1, 3.2, 4.0, and 4.1
- [#56](https://github.com/jpignata/temping/pull/56): Add license to gemspec - Thanks @leapingfrogs

## 3.9.0 - 2017-03-16
- [#53](https://github.com/jpignata/temping/pull/53): Add option for specifying parent class - Thanks @nathanstitt

## 3.8.0 - 2017-02-07
- [#49](https://github.com/jpignata/temping/pull/49): Always clear dependencies on `Temping.teardown` using 
  `ActiveSupport::Dependencies::Reference.clear!` - Thanks @faucct
- Remove `clear_dependencies` option from `Temping.teardown`

## 3.7.1 - 2016-08-24
- Primary key fix. Properly set primary key in table when creating it.

## 3.7.0 - 2016-08-24
- [#47](https://github.com/jpignata/temping/pull/47),
[#45](https://github.com/jpignata/temping/pull/45): 
Option to clear dependencies cache on `teardown`

## 3.6.1 - 2016-03-24
- [#40](https://github.com/jpignata/temping/pull/40): Fixed unexpected model reflections caching - Thanks @faucct

## 3.6.0 - 2016-03-23
- [#44](https://github.com/jpignata/temping/pull/44): Add support for Rails 5 ApplicationRecord - Thanks @bryanwoods

## 3.5.0 - 2016-03-23
- [#39](https://github.com/jpignata/temping/pull/39): Add `Temping.cleanup` method - Thanks @bolshakov

## 3.4.0 - 2016-03-23
- [#38](https://github.com/jpignata/temping/pull/38): Add abiltity to override create_table options - Thanks @bolshakov

## 3.3.1 - 2016-03-23
- [#31](https://github.com/jpignata/temping/pull/31): Patch an issue when you create multiple models with Temping with the same name - Thanks @oneamtu!

## 3.3.0 - 2015-05-18
- [#20](https://github.com/jpignata/temping/pull/20): Add `Temping.teardown`. Thanks @grn!
