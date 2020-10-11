[beeline](https://github.com/inertia186/beeline-rb)
=======

BeeLine is a [BeeChat](https://beechat.hive-engine.com/) Client Framework for Ruby.  BeeChat has been designed by [@reazuliqbal](https://hive.blog/@reazuliqbal).  BeeLine provides abstraction to for ruby developers to interact through the BeeChat [API](https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md).

#### Installation

Add to your `Gemspec`

```ruby
gem 'beeline-rb', require 'beeline'
```

```bash
bundle install
```

**--or--**

In your project ...

```bash
gem install beeline-rb
```

```ruby
require 'beeline'
```

#### Usage

From the root of your project, add a file called `config.yml` containing (using your own account information):

```yaml
# Example config.yml

:chain:
  :hive_account: social
  :hive_public_key: STM5ctejUsoZ9FwfCaVbNvWYYgNMBo9TVsHSE8wHrqAmNJi6sDctt
  :hive_posting_wif: 5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC
  :hive_api_url: https://api.openhive.network
```

In your project, access the session:

```ruby
require 'beeline'

bot = Beeline::Bot.new(prefix: '$')

# Just match on a message.
bot.message('Ping!') do
  'Pong!'
end

# Match on a pattern.
bot.message(/\d+/) do
  'Yes, those are numbers.'
end

# Respond to `$time` with current time.
bot.command(:time) do
  Time.now.to_s
end

# Respond to `$say` with reply.
bot.command(:say) do |args|
  if args.nil?
    'What do you want me to say?'
  else
    "You wanted me to say: #{args}"
  end
end

# Start the bot run loop.
bot.run
```

---

<center>
  <img src="https://i.imgur.com/h26ye3w.png" />
</center>

See some of my previous Ruby How To posts in: [#radiator](https://hive.blog/created/radiator) [#ruby](https://hive.blog/created/ruby)

## Get in touch!

If you're using Tender, I'd love to hear from you.  Drop me a line and tell me what you think!  I'm @inertia on Hive.
  
## License

I don't believe in intellectual "property".  If you do, consider BeeLine as licensed under a Creative Commons <a href="http://creativecommons.org/publicdomain/zero/1.0/"><img src="http://i.creativecommons.org/p/zero/1.0/80x15.png" alt="CC0" /></a> License.
