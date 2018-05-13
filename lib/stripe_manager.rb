require "stripe"

class StripeManager
  PLANS = {
    company_sizes: {
      test: "test",
      small: "1-50 employees",
      large: "51-120 employees",
    },

    periods: {
      monthly: {
        description: "Billed Monthly",
        plans: [
          {
            name: "Test - monthly",
            admin_only: true,
            company_size: "test",
            employees_count: "1-50 employees",
            id: "test-monthly",
            period: "month",
            description: "Test plan for $1.",
            amount: 1
          },
          {
            name: "Small Company (1-50 employees) - monthly",
            company_size: "small",
            employees_count: "1-50 employees",
            id: "small-monthly",
            period: "month",
            description: "For Restaurants with 1-50 employees.",
            amount: 59
          },
          {
            name: "Large Company (51-120 employees) - monthly",
            company_size: "large",
            employees_count: "51-120 employees",
            id: "large-monthly",
            period: "month",
            description: "For Restaurants with 51-120 employees.",
            amount: 99,
          }
        ]
      },
      yearly: {
        description: "Billed Yearly - 1 month free",
        plans: [
          {
            name: "Small Company (1-50 employees) - yearly",
            company_size: "small",
            employees_count: "1-50 employees",
            id: "small-yearly",
            description: "For Restaurants with 1-50 employees.",
            period: 'year',
            amount: 649
          },
          {
            name: "Large Company (51-120 employees) - yearly",
            company_size: "large",
            employees_count: "51-120 employees",
            id: "large-yearly",
            description: "For Restaurants with 51-120 employees.",
            period: 'year',
            amount: 1089,
          }
        ]
      }
    }
  }

  class << self
    def configure
      Stripe.api_key = ENV["stripe_api_key"]
      Stripe.max_network_retries = 3
    end

    def create_customer(user)
      Stripe::Customer.create(email: user.email)
    end

    def subscribe_to_plan(user, params)
      user.set_default_card(params[:cardChoosen]) if params[:cardChoosen].present?
      Stripe::Subscription.create(
        customer: user.stripe_id,
        items: [{
          plan: params[:subscription_plan]
        }]
      )
    end
  end
end