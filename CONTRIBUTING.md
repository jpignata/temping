Want to contribute to the development of temping! Great! Here's what you can do:

* suggest a feature or submit a bug at https://github.com/jpignata/temping/issues
* contribute code or documentation by submitting a pull request at https://github.com/jpignata/temping/pulls

If you submit code make sure that the test suite is still green. The code is
currently tested against SQLite3, PostgreSQL and MySQL. Before running the test
suite against each of these databases you must perform a bit of setup:

```
$ rake db:postgresql:create # to set up PostgreSQL
$ rake db:mysql:create # to set up MySQL
```

The configuration used to access the databases is stored in
`spec/config.default.yml`. After running these commands you can run the test
suite with `rake`. If you want to test a particular database adapter run
`rake spec:<adapter name>`, e.g. `rake spec:mysql`.

If, for any reason, you want to recreate the test databases you can do so by
running `rake db:postgresql:drop db:mysql:drop`.
