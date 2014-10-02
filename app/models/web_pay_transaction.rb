class WebPayTransaction
  attr_accessor :order,
                :response, :response_error, :response_type, :card

  delegate :currency, :amount, :transaction_token, :card_token, :wallet_id,
           to: :order

  def initialize(order)
    self.order = order
  end

  def charge!
    if self.wallet_id.present? && self.card_token.present?
      raise "wallet_id and card_token present, it should be one of these."
    end
    if self.wallet_id.blank? && self.card_token.blank?
      raise "wallet_id or card_token should be present."
    end
    if self.wallet_id.present?
      wallet = self.order.user.wallets.find_by_uuid(self.wallet_id) || raise("Invalid wallet_id")
      self.card = wallet.token
    else # create customer
      create_customer!
    end
    create_charge!
  end

  def create_charge!
    begin
      self.response = self.webpay.charge.create(
          amount: self.amount,
          currency: self.currency,
          customer: self.card,
          description: self.transaction_token
      )
      true
    rescue => e
      # save and re-raise error.
      self.response_error = e
      raise e
    end
  end
  def create_customer!
    begin
      # instead of full card info, use onetime token.
      wallet = prepare_wallet
      wallet.save!
      self.order.wallet_id = wallet.id
      self.card = wallet.token
    rescue => e
      # save and re-raise error.
      self.response_error = e
      raise e
    end
  end
  def prepare_wallet
    self.order.user.wallets.from_card_token(card_token: self.card_token)
  end
  def webpay
    WebPay.new ENV['WEBPAY_API_KEY']
  end
end
