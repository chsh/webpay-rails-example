class Wallet < ActiveRecord::Base
  belongs_to :user

  serialize :customer
  serialize :last_error

  attr_accessor :card_token

  validates :token, :fingerprint, presence: true, uniqueness: true
  validates :exp_year, :exp_month, :customer_created_at,
            presence: true

  before_create :generate_uuid, :fill_exp_year_and_month
  after_destroy :remove_webpay_customer_object

  scope :not_expired, -> (today = nil) {
    today ||= Date.today
    where('? <= exp_year_and_month', sprintf('%02d%02d', today.year % 100, today.month))
  }
  scope :available, -> (today = nil) {
    not_expired(today)
  }

  def self.from_card_token(params)
    wallet = self.new params
    wallet.create_customer_object
    wallet.setup_using_customer
    wallet
  end

  def save_last_error(webpay_error_response)
    self.last_error_occurred_at = Time.now
    self.last_error = webpay_error_response
    self.num_errors += 1
    self.save
  end

  def create_customer_object
    webpay = WebPay.new(ENV['WEBPAY_API_KEY'])
    customer_object = webpay.customer.create card: self.card_token,
                                             email: self.user.email
    self.customer = customer_object.to_hash
  end

  def setup_using_customer
    self.token = customer_path '/id'
    self.fingerprint = customer_path '/active_card/fingerprint'
    self.exp_year = customer_path '/active_card/exp_year'
    self.exp_month = customer_path '/active_card/exp_month'
    self.customer_created_at = customer_path '/created'
  end

  def active_card_type
    self.customer['active_card']['type'] if self.customer.present?
  end

  def active_card_last4
    self.customer['active_card']['last4'] if self.customer.present?
  end

  def exp_month_and_year
    @exp_month_and_year ||= build_exp_month_and_year
  end

  private
  def remove_webpay_customer_object
    webpay = WebPay.new(C.by(:webpay).api_key)
    webpay.customer.delete id: self.token
  end

  private
  def build_exp_year_and_month
    sprintf("%02d%02d", self.exp_year % 100, self.exp_month)
  end
  def fill_exp_year_and_month
    self.exp_year_and_month = build_exp_year_and_month
  end
  def build_exp_month_and_year
    sprintf("%02d/%02d", self.exp_month, self.exp_year % 100)
  end
end
