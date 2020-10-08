require 'test_helper'

class Beeline::BotTest < Beeline::Test
  def setup
    @payload = {
      'conversation_id' => '01EM4W16D70WRNM7MA3XZR84BT',
      'from' => 'alice'
    }
  end
  
  def test_status
    VCR.use_cassette('bot_process_status', record: VCR_RECORD_MODE) do
      result = bot.process_status({"authenticated" => true})
      assert_nil result
    end
  end
  
  def test_not_status
    VCR.use_cassette('bot_process_status_not_authenticated', record: VCR_RECORD_MODE) do
      assert_raises Exception do
        result = bot.process_status({"authenticated" => false})
        assert_nil result
      end
    end
  end
  
  def test_ping
    VCR.use_cassette('bot_process_ping', record: VCR_RECORD_MODE) do
      result = bot.process_chat_message(@payload.merge('content' => 'Ping!'))
      refute_nil result
    end
  end
  
  def test_help
    VCR.use_cassette('bot_process_help', record: VCR_RECORD_MODE) do
      result = bot.process_chat_message(@payload.merge('content' => '$help'))
      refute_nil result
    end
  end
  
  def test_version
    VCR.use_cassette('bot_process_version', record: VCR_RECORD_MODE) do
      result = bot.process_chat_message(@payload.merge('content' => '$version'))
      assert_nil result
    end
  end
  
  def test_slap
    VCR.use_cassette('bot_process_slap_bob', record: VCR_RECORD_MODE) do
      result = bot.process_chat_message(@payload.merge('content' => '$slap bob'))
      assert_nil result
    end
  end
  
  def test_slap_no_target
    VCR.use_cassette('bot_process_slap_empty', record: VCR_RECORD_MODE) do
      result = bot.process_chat_message(@payload.merge('content' => '$slap'))
      assert_nil result
    end
  end
end
