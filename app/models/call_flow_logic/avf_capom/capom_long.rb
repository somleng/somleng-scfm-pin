class CallFlowLogic::AvfCapom::CapomLong < CallFlowLogic::AvfCapom::CapomBase
  aasm :whiny_transitions => false do
    state :initialized, :initial => true
    state :playing_introduction
    state :gathering_received_transfer
    state :gathering_received_transfer_amount
    state :recording_transfer_not_received_reason
    state :playing_transfer_not_received_exit_message
    state :finished
    state :gathering_paid_for_transport
    state :gathering_paid_for_transport_amount
    state :gathering_safe_at_venue
    state :gathering_fee_paid
    state :gathering_fee_paid_amount
    state :recording_goods_purchased
    state :gathering_item_availability
    state :gathering_idp_status
    state :gathering_water_availability
    state :gathering_sickness
    state :gathering_preferred_transfer_modality
    state :playing_completed_survey_message

    before_all_events :set_current_state
    after_all_events :set_status

    event :step do
      before :set_previous_status

      transitions :from => :initialized,
                  :to => :playing_introduction

      transitions :from => :playing_introduction,
                  :to =>   :gathering_received_transfer

      transitions :from => :gathering_received_transfer,
                  :to => :recording_transfer_not_received_reason,
                  :if => :answered_no?

      transitions :from => :recording_transfer_not_received_reason,
                  :to => :playing_transfer_not_received_exit_message

      transitions :from => :playing_transfer_not_received_exit_message,
                  :to => :finished

      transitions :from => :gathering_received_transfer,
                  :to => :gathering_received_transfer_amount,
                  :if => :answered_yes?

      transitions :from => :gathering_received_transfer_amount,
                  :to => :gathering_paid_for_transport,
                  :if => :answered_any?

      transitions :from => :gathering_paid_for_transport,
                  :to => :gathering_paid_for_transport_amount,
                  :if => :answered_yes?

      transitions :from => :gathering_paid_for_transport,
                  :to => :gathering_safe_at_venue,
                  :if => :answered_no?

      transitions :from => :gathering_paid_for_transport_amount,
                  :to => :gathering_safe_at_venue,
                  :if => :answered_any?

      transitions :from => :gathering_safe_at_venue,
                  :to => :gathering_fee_paid,
                  :if => :answered_yes_or_no?

      transitions :from => :gathering_fee_paid,
                  :to => :gathering_fee_paid_amount,
                  :if => :answered_yes?

      transitions :from => :gathering_fee_paid,
                  :to => :recording_goods_purchased,
                  :if => :answered_no?

      transitions :from => :gathering_fee_paid_amount,
                  :to => :recording_goods_purchased,
                  :if => :answered_any?

      transitions :from => :recording_goods_purchased,
                  :to => :gathering_item_availability

      transitions :from => :gathering_item_availability,
                  :to => :gathering_idp_status,
                  :if => :answered_yes_or_no?

      transitions :from => :gathering_idp_status,
                  :to => :gathering_water_availability,
                  :if => :answered_yes_or_no?

      transitions :from => :gathering_water_availability,
                  :to => :gathering_sickness,
                  :if => :answered_any?

      transitions :from => :gathering_sickness,
                  :to => :gathering_preferred_transfer_modality,
                  :if => :answered_yes_or_no?

      transitions :from => :gathering_preferred_transfer_modality,
                  :to => :playing_completed_survey_message,
                  :if => :answered_yes_or_no?

      transitions :from => :playing_completed_survey_message,
                  :to => :finished
    end
  end

  private

  def twiml_for_gathering_received_transfer_amount
    gather(:num_digits => 3)
  end

  def twiml_for_gathering_paid_for_transport
    gather(:num_digits => 1)
  end

  def twiml_for_gathering_paid_for_transport_amount
    gather(:num_digits => 3)
  end

  def twiml_for_gathering_item_availability
    gather(:num_digits => 1)
  end

  def twiml_for_gathering_idp_status
    gather(:num_digits => 1)
  end

  def twiml_for_gathering_water_availability
    gather(:num_digits => 3)
  end

  def twiml_for_gathering_sickness
    gather(:num_digits => 1)
  end

  def twiml_for_gathering_preferred_transfer_modality
    gather(:num_digits => 1)
  end
end
