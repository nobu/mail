require 'spec_helper'

describe Mail::Part do

  it "should put content-ids into parts" do
    part = Mail::Part.new do
      body "This is Text"
    end
    part.to_s
    part.content_id.should_not be_nil
  end

  it "should preserve any content id that you put into it" do
    part = Mail::Part.new do
      content_id "<thisis@acontentid>"
      body "This is Text"
    end
    part.content_id.should == "<thisis@acontentid>"
  end

  it "should return an inline content_id" do
    part = Mail::Part.new do
      content_id "<thisis@acontentid>"
      body "This is Text"
    end
    part.cid.should == "thisis@acontentid"
    STDERR.should_receive(:puts).with("Part#inline_content_id is deprecated, please call Part#cid instead")
    part.inline_content_id.should == "thisis@acontentid"
  end


  it "should URL escape its inline content_id" do
    part = Mail::Part.new do
      content_id "<thi%%sis@acontentid>"
      body "This is Text"
    end
    part.cid.should == "thi%25%25sis@acontentid"
    STDERR.should_receive(:puts).with("Part#inline_content_id is deprecated, please call Part#cid instead")
    part.inline_content_id.should == "thi%25%25sis@acontentid"
  end

  it "should add a content_id if there is none and is asked for an inline_content_id" do
    part = Mail::Part.new
    part.cid.should_not be_nil
    STDERR.should_receive(:puts).with("Part#inline_content_id is deprecated, please call Part#cid instead")
    part.inline_content_id.should_not be_nil
  end

  it "should respond correctly to inline?" do
    part = Mail::Part.new(:content_disposition => 'attachment')
    part.should_not be_inline

    part = Mail::Part.new(:content_disposition => 'inline')
    part.should be_inline
  end


  describe "parts that have a missing header" do
    it "should not try to init a header if there is none" do
      part =<<PARTEND

The original message was received at Mon, 24 Dec 2007 10:03:47 +1100
from 60-0-0-146.static.tttttt.com.au [60.0.0.146]

This message was generated by mail12.tttttt.com.au

   ----- The following addresses had permanent fatal errors -----
<edwin@zzzzzzz.com>
    (reason: 553 5.3.0 <edwin@zzzzzzz.com>... Unknown E-Mail Address)

   ----- Transcript of session follows -----
... while talking to mail.zzzzzz.com.:
>>> DATA
<<< 553 5.3.0 <edwin@zzzzzzz.com>... Unknown E-Mail Address
550 5.1.1 <edwin@zzzzzzz.com>... User unknown
<<< 503 5.0.0 Need RCPT (recipient)

--
This message has been scanned for viruses and
dangerous content by MailScanner, and is
believed to be clean.
PARTEND
      STDERR.should_not_receive(:puts)
      Mail::Part.new(part)
    end
  end

  describe "delivery status reports" do
    before(:each) do
      part =<<ENDPART
Content-Type: message/delivery-status

Reporting-MTA: dns; mail12.rrrr.com.au
Received-From-MTA: DNS; 60-0-0-146.static.tttttt.com.au
Arrival-Date: Mon, 24 Dec 2007 10:03:47 +1100

Final-Recipient: RFC822; edwin@zzzzzzz.com
Action: failed
Status: 5.3.0
Remote-MTA: DNS; mail.zzzzzz.com
Diagnostic-Code: SMTP; 553 5.3.0 <edwin@zzzzzzz.com>... Unknown E-Mail Address
Last-Attempt-Date: Mon, 24 Dec 2007 10:03:53 +1100
ENDPART
      @delivery_report = Mail::Part.new(part)
    end

    it "should know if it is a delivery-status report" do
      @delivery_report.should be_delivery_status_report_part
    end

    it "should create a delivery_status_data header object" do
      @delivery_report.delivery_status_data.should_not be_nil
    end

    it "should be bounced" do
      @delivery_report.should be_bounced
    end

    it "should say action 'delayed'" do
      @delivery_report.action.should == 'failed'
    end

    it "should give a final recipient" do
      @delivery_report.final_recipient.should == 'RFC822; edwin@zzzzzzz.com'
    end

    it "should give an error code" do
      @delivery_report.error_status.should == '5.3.0'
    end

    it "should give a diagostic code" do
      @delivery_report.diagnostic_code.should == 'SMTP; 553 5.3.0 <edwin@zzzzzzz.com>... Unknown E-Mail Address'
    end

    it "should give a remote-mta" do
      @delivery_report.remote_mta.should == 'DNS; mail.zzzzzz.com'
    end

    it "should be retryable" do
      @delivery_report.should_not be_retryable
    end

  end

  it "should correctly parse plain text raw source and not truncate after newlines - issue 208" do
    plain_text = "First Line\n\nSecond Line\n\nThird Line\n\n"
    #Note: trailing \n\n is stripped off by Mail::Part initialization
    part = Mail::Part.new(plain_text)
    part[:content_type].content_type.should == 'text/plain'
    part.to_s.should match /^First Line\r\n\r\nSecond Line\r\n\r\nThird Line/
  end

end
