# Nrepl

Nrepl is a ruby library to communicate with a clojure nrepl

## Installation

Add this line to your application's Gemfile:

    gem 'nrepl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nrepl

## Usage

### Connecting to an existing repl

```ruby
repl = Nrepl::Repl.connect(1234) # connect to port 1234
```

### Evaluating code in the repl

```ruby
repl.eval "(+ 3 3)" # => an array of responses messages from the repl
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
