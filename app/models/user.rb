class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include DeviseModel

  has_one :restaurant, dependent: :destroy
  has_many :calculations, dependent: :destroy

  after_create :create_restaurant
  after_create :link_to_stripe, unless: "Rails.env.test?"

  field :name
  field :stripe_id
  field :is_admin, type: Boolean, default: false
  validates :email, uniqueness: true

  def create_restaurant
    Restaurant.create(user: self) unless self.restaurant
  end

  def link_to_stripe  
    customer = StripeManager.create_customer(self)
    self.stripe_id = customer["id"]
    self.save
  end

  def add_source(token)
    #fetch the customer 
    customer = stripe_user
    #Retrieve the card fingerprint using the stripe_card_token  
    card_fingerprint = Stripe::Token.retrieve(token).try(:card).try(:fingerprint) 
    # check whether a card with that fingerprint already exists
    default_card = customer.sources.all.data.select{|card| card.fingerprint ==  card_fingerprint}.last if card_fingerprint 
    #create new card if do not already exists
    default_card = customer.sources.create(source: token) unless default_card 

    default_card
  end

  def set_default_card(card_id)
    su = stripe_user
    su.default_source = card_id
    su.save
  end

  def delete_card(card_id)
    su = stripe_user
    card = su.sources.retrieve(card_id)
    card.delete
  end

  def get_card(card_id)
    su = stripe_user
    su.sources.retrieve(card_id)
  end

  def stripe_user_cards
    stripe_user.sources.all(:object => "card")
  end

  def stripe_user_subscriptions
    stripe_user[:subscriptions]
  end

  def subscribe(params)
    StripeManager.subscribe_to_plan(self, params)
  end

  def unsubscribe(plan)
    su = stripe_user

    active_subacriptions = su[:subscriptions][:data]
    plan_subscriptions = active_subacriptions.select{|s| s[:plan][:id] }
    plan_subscription = plan_subscriptions.any? ? plan_subscriptions.first : false
    if plan_subscription
      sub = Stripe::Subscription.retrieve(plan_subscription[:id])
      sub.delete
    else
      false
    end
  end

  def stripe_user
    Stripe::Customer.retrieve(stripe_id)
  end

  def has_access_to?(id)
    true
  end
end