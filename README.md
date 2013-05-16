# Defensor

Unofficial gem for working with Defensio API 2.0

## Installation

Add this line to your application's Gemfile:

    gem 'defensor'

And then execute:

    $ bundle

Add initializer with api_key

    Defensor.api_key = "YOUR_KEY_HERE"

## Usage

Post document for spam chek:

    d = Defensor.new(content: "lalalalalalal", type: :forum, platform: "my_awesome_app")
    d.post_document
    => [200, {"status"=>"success", "message"=>"", "api-version"=>"2.0", "signature"=>"1fd5c9de6a77f28256fba1", "allow"=>true, "spaminess"=>0.05, "classification"=>"legitimate", "profanity-match"=>false}]

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
