# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Notifier do
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end

  it "deployed" do
    @expected.subject = '[DEPLOYMENT] r666 deployed'
    @expected.from    = "wizzadmin@peerworks.org"
    @expected.to      = "wizzadmin@peerworks.org"
    @expected.body    = read_fixture('deployed')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifier.create_deployed("", "the beast", "666", "", "", @expected.date).encoded
  end

private
  def read_fixture(action)
    IO.readlines("#{FIXTURES_PATH}/notifier/#{action}")
  end

  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end
