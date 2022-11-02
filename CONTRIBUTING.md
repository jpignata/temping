Want to contribute to the development of temping? Great!

Here's what you can do:

* suggest a feature or submit a bug at https://github.com/jpignata/temping/issues
* contribute code or documentation by submitting a pull request at https://github.com/jpignata/temping/pulls

If you submit code make sure that the test suite is still green by either manually running 
the tests or making use of the CI, which starts upon every pull request. 

The code is currently tested against several versions of SQLite3, PostgreSQL and MySQL. 
If you want to run the tests manually please first make sure you have Docker 
installed and then run

```shell
$ docker-compose up -d
```

to start the container. Once the container is up and running you can run 

```shell
$ rake
``` 

to run the whole test suite. 

If you want to test a particular database adapter version run
`rake spec:<adapter version>`, e.g. `rake spec:mysql8.0` 
(the name should correspond to keys in `spec/config.default.yml`).

You can prepend the call with a specific gemfile 
(located in `gemfiles` directory) to test against a particular 
ActiveRecord version. This is done with the help of 
[Appraisal gem](https://github.com/thoughtbot/appraisal). 
For example:

```shell
$ BUNDLE_GEMFILE=gemfiles/activerecord_6.1.gemfile rake
```

The configuration used to access the databases is stored in
`spec/config.default.yml` and `docker-compose.yml`.
