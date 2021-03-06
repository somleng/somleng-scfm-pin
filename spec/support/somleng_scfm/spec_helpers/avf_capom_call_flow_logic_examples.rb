module SomlengScfm::SpecHelpers::AvfCapomCallFlowLogic
  module BaseHelpers
    def status
      nil
    end

    def call_flow_data
      @call_flow_data ||= { "status" => status }
    end

    def contact_metadata
      @contact_metadata ||= { "call_flow_data" => { described_class.to_s => call_flow_data } }
    end

    def contact
      @contact ||= create(:contact, :metadata => contact_metadata)
    end

    def phone_call_factory_attributes
      @phone_call_factory_attributes ||= { :contact => contact }
    end

    def phone_call
      @phone_call ||= create(:phone_call, phone_call_factory_attributes)
    end

    def event_details
      @event_details ||= generate(:twilio_remote_call_event_details)
    end

    def event_factory_attributes
      @event_factory_attributes ||= { :details => event_details, :phone_call => phone_call }
    end

    def event
      @event ||= create(:remote_phone_call_event, event_factory_attributes)
    end

    def current_url
      @current_url ||= "http://scfm.example.com/api/remote_phone_call_events"
    end
  end

  module ToXmlHelpers
    def setup_no_status_change
      subject.previous_status = status
      subject.aasm.current_state = status.to_sym
    end

    def asserted_play_file_url(filename)
      [
        described_class::DEFAULT_PLAY_FILE_BASE_URL,
        filename.to_s + described_class::DEFAULT_PLAY_FILE_EXTENSION
      ].join("/")
    end

    def assert_response!
      expect(response).to be_present
    end

    def assert_xml!
      assert_response!
    end

    def assert_play!(response, options = {})
      options[:url] ||= status
      play_response = response["Play"]
      play_response = play_response[options[:index]] if options[:index]
      expect(play_response).to eq(asserted_play_file_url(options[:url]))
    end

    def assert_play_status_and_redirect!
      assert_response!
      expect(response["Redirect"]).to eq(current_url)
      assert_play!(response)
    end

    def assert_play_status_and_hangup!
      assert_response!
      assert_play!(response)
      expect(response).to have_key("Hangup")
    end

    def assert_did_not_understand_response!
      assert_play!(gather_response, :index => 1)
      assert_play!(gather_response, :index => 0, :url => :did_not_understand_response)
    end

    def assert_play_and_record!
      assert_response!
      assert_play!(response)
      expect(response).to have_key("Record")
    end

    def assert_finished!
      assert_response!
      expect(response).to have_key("Hangup")
    end

    def xml
      @xml ||= subject.to_xml
    end

    def response
      @response ||=  Hash.from_xml(xml)["Response"]
    end

    def gather_response
      @gather_response ||= response["Gather"]
    end
  end

  module RunHelpers
    def new_call_flow_data
      @new_call_flow_data ||= contact.reload.metadata["call_flow_data"][described_class.to_s]
    end

    def event_details_with_response(response, event_details)
      if response == :yes
        event_details.merge("Digits" => "1")
      elsif response == :no
        event_details.merge("Digits" => "2")
      else
        event_details.merge("Digits" => response && response.to_s)
      end
    end

    def setup_scenario
      super
      subject.run!
    end

    def assert_run!
      expect(subject.status).to eq(asserted_new_status.to_s)
      expect(new_call_flow_data["transitioned_to_#{asserted_new_status}_by"]).to eq(event.id) if asserted_new_status != status
      expect(new_call_flow_data["status"]).to eq(asserted_new_status.to_s)
    end
  end
end

RSpec.shared_examples_for("dtmf_yes_no_state_transition") do |options = {}|
  let(:options) { options }

  context "responded with yes" do
    let(:event_details) { event_details_with_response(:yes, super()) }
    let(:asserted_new_status) { options[:asserted_yes_status] }
    it { assert_run! }
  end

  context "responded with no" do
    let(:event_details) { event_details_with_response(:no, super()) }
    let(:asserted_new_status) { options[:asserted_no_status] }
    it { assert_run! }
  end

  context "no response" do
    let(:event_details) { event_details_with_response(nil, super()) }
    let(:asserted_new_status) { status }
    it { assert_run! }
  end
end

RSpec.shared_examples_for("dtmf_any_input_state_transition") do |options = {}|
  let(:options) { options }

  context "responded with '#{options[:input]}'" do
    let(:event_details) { event_details_with_response(options[:input].to_s, super()) }
    let(:asserted_new_status) { options[:asserted_new_status] }
    it { assert_run! }
  end

  context "no response" do
    let(:event_details) { event_details_with_response(nil, super()) }
    let(:asserted_new_status) { status }
    it { assert_run! }
  end
end

RSpec.shared_examples_for "twiml_gather" do |options = {}|
  let(:options) { options }

  def assert_xml!
    super
    expect(gather_response).to be_present
    expect(gather_response["numDigits"]).to eq(options[:num_digits].to_s)
  end

  context "no status change" do
    def setup_scenario
      setup_no_status_change
    end

    def assert_xml!
      super
      assert_did_not_understand_response!
    end

    it { assert_xml! }
  end

  context "status changed" do
    def assert_xml!
      super
      assert_play!(gather_response)
    end

    it { assert_xml! }
  end
end

RSpec.shared_examples_for "avf_capom_call_flow_logic" do
  describe "state_machine" do
    context "by default" do
      it { is_expected.to be_initialized }
    end
  end
end

RSpec.shared_examples_for "avf_capom_call_flow_logic_to_xml" do
  context "status: nil" do
    let(:status) { nil }

    def assert_xml!
      super
      expect(response["Say"]).to eq("Sorry. The application has no response. Goodbye.")
    end

    it { assert_xml! }
  end

  context "status: '#{described_class::STATE_PLAYING_INTRODUCTION}'" do
    let(:status) { described_class::STATE_PLAYING_INTRODUCTION }
    it { assert_play_status_and_redirect! }
  end

  context "status: '#{described_class::STATE_GATHERING_RECEIVED_TRANSFER}'" do
    let(:status) { described_class::STATE_GATHERING_RECEIVED_TRANSFER }
    include_examples("twiml_gather", :num_digits => "1")
  end

  context "status: '#{described_class::STATE_RECORDING_TRANSFER_NOT_RECEIVED_REASON}'" do
    let(:status) { described_class::STATE_RECORDING_TRANSFER_NOT_RECEIVED_REASON }
    it { assert_play_and_record! }
  end

  context "status: '#{described_class::STATE_PLAYING_TRANSFER_NOT_RECEIVED_EXIT_MESSAGE}'" do
    let(:status) { described_class::STATE_PLAYING_TRANSFER_NOT_RECEIVED_EXIT_MESSAGE }
    it { assert_play_status_and_hangup! }
  end

  context "status: '#{described_class::STATE_FINISHED}'" do
    let(:status) { described_class::STATE_FINISHED }
    it { assert_finished! }
  end

  context "status: '#{described_class::STATE_GATHERING_SAFE_AT_VENUE}'" do
    let(:status) { described_class::STATE_GATHERING_SAFE_AT_VENUE }
    include_examples("twiml_gather", :num_digits => "1")
  end

  context "status: '#{described_class::STATE_GATHERING_FEE_PAID}'" do
    let(:status) { described_class::STATE_GATHERING_FEE_PAID }
    include_examples("twiml_gather", :num_digits => "1")
  end

  context "status: '#{described_class::STATE_GATHERING_FEE_PAID_AMOUNT}'" do
    let(:status) { described_class::STATE_GATHERING_FEE_PAID_AMOUNT }
    include_examples("twiml_gather", :num_digits => "3")
  end

  context "status: '#{described_class::STATE_PLAYING_COMPLETED_SURVEY_MESSAGE}'" do
    let(:status) { described_class::STATE_PLAYING_COMPLETED_SURVEY_MESSAGE }
    it { assert_play_status_and_hangup! }
  end
end

RSpec.shared_examples_for "avf_capom_call_flow_logic_run" do
  context "status: nil" do
    let(:status) { nil }
    let(:asserted_new_status) { described_class::STATE_PLAYING_INTRODUCTION }
    it { assert_run! }
  end

  context "status: '#{described_class::STATE_PLAYING_INTRODUCTION}'" do
    let(:status) { described_class::STATE_PLAYING_INTRODUCTION }
    let(:asserted_new_status) { described_class::STATE_GATHERING_RECEIVED_TRANSFER }
    it { assert_run! }
  end

  context "status: '#{described_class::STATE_RECORDING_TRANSFER_NOT_RECEIVED_REASON}'" do
    let(:status) { described_class::STATE_RECORDING_TRANSFER_NOT_RECEIVED_REASON }
    let(:asserted_new_status) { described_class::STATE_PLAYING_TRANSFER_NOT_RECEIVED_EXIT_MESSAGE }
    it { assert_run! }
  end

  context "status: '#{described_class::STATE_PLAYING_TRANSFER_NOT_RECEIVED_EXIT_MESSAGE}'" do
    let(:status) { described_class::STATE_PLAYING_TRANSFER_NOT_RECEIVED_EXIT_MESSAGE }
    let(:asserted_new_status) { described_class::STATE_FINISHED }
    it { assert_run! }
  end

  context "status: '#{described_class::STATE_GATHERING_FEE_PAID}'" do
    let(:status) { described_class::STATE_GATHERING_FEE_PAID }
    include_examples(
      "dtmf_yes_no_state_transition",
      :asserted_yes_status => described_class::STATE_GATHERING_FEE_PAID_AMOUNT,
      :asserted_no_status => described_class::STATE_RECORDING_GOODS_PURCHASED
    )
  end

  context "status: '#{described_class::STATE_GATHERING_FEE_PAID_AMOUNT}'" do
    let(:status) { described_class::STATE_GATHERING_FEE_PAID_AMOUNT }
    include_examples(
      "dtmf_any_input_state_transition",
      :input => "500",
      :asserted_new_status => described_class::STATE_RECORDING_GOODS_PURCHASED
    )
  end

  context "status: '#{described_class::STATE_PLAYING_COMPLETED_SURVEY_MESSAGE}'" do
    let(:status) { described_class::STATE_PLAYING_COMPLETED_SURVEY_MESSAGE }
    let(:asserted_new_status) { described_class::STATE_FINISHED }
    it { assert_run! }
  end
end
