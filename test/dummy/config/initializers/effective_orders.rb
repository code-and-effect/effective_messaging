EffectiveOrders.setup do |config|
  # Configure Database Tables
  config.orders_table_name = :orders
  config.order_items_table_name = :order_items
  config.carts_table_name = :carts
  config.cart_items_table_name = :cart_items
  config.customers_table_name = :customers
  config.subscriptions_table_name = :subscriptions
  config.products_table_name = :products

  # Layout Settings
  # config.layout = { application: 'application', admin: 'admin' }

  # Filter the @orders on admin/orders#index screen
  # config.orders_collection_scope = Proc.new { |scope| scope.where(...) }

  # Require these addresses when creating a new Order.  Works with effective_addresses gem
  config.billing_address = true
  config.shipping_address = false

  # Use effective_obfuscation gem to change order.id into a seemingly random 10-digit number
  config.obfuscate_order_ids = false

  # Effective Quickbooks Synchronization
  config.use_effective_qb_sync = false

  # If set, the orders#new screen will render effective/orders/_order_note_fields to capture any Note info
  config.collect_note = false
  config.collect_note_required = false
  config.collect_note_message = ''

  # If true, the orders#new screen will render effective/orders/_terms_and_conditions_fields to require a Terms of Service boolean
  # config.terms_and_conditions_label can be a String or a Proc
  # config.terms_and_conditions_label = Proc.new { |order| "Yes, I agree to the #{link_to 'terms and conditions', terms_and_conditions_path}." }
  config.terms_and_conditions = false
  config.terms_and_conditions_label = 'I agree to the terms and conditions.'

  # Tax Calculation Method
  # The Effective::TaxRateCalculator considers the order.billing_address and assigns a tax based on country & state code
  # Right now, only Canadian provinces are supported. Sorry.
  # To always charge 12.5% tax: Proc.new { |order| 12.5 }
  # To always charge 0% tax: Proc.new { |order| 0 }
  # If the Proc returns nil, the tax rate will be calculated once again whenever the order is validated
  # An order must have a tax rate (even if the value is 0) to be purchased
  config.order_tax_rate_method = Proc.new { |order| Effective::TaxRateCalculator.new(order: order).tax_rate }

  # Minimum Charge
  # Prevent orders less than this value from being purchased
  # Stripe doesn't allow orders less than $0.50
  # Set to nil for no minimum charge
  # Default value is 50 cents, or $0.50
  config.minimum_charge = 50

  # Free Orders
  # Allow orders with a total of 0.00 to be purchased (regardless of the minimum charge setting)
  config.free_enabled = true

  # Mark as Paid
  # Mark an order as paid without going through a processor
  # This is accessed via the admin screens only. Must have can?(:admin, :effective_orders)
  config.mark_as_paid_enabled = false

  # Pretend Purchase
  # Display a 'Purchase order' button on the Checkout screen allowing the user
  # to purchase an Order without going through the payment processor.
  # WARNING: Setting this option to true will allow users to purchase! an Order without entering a credit card
  # WARNING: When true, users can purchase! anything without paying money
  config.pretend_enabled = !Rails.env.production?
  config.pretend_message = '* payment information is not required to process this order at this time.'

  # Mailer Settings
  # effective_orders sends out receipts to buyers and admins as well as trial and subscription related emails.
  # For all the emails, the same :subject_prefix will be prefixed.  Leave as nil / empty string if you don't want any prefix
  #
  # All the subject_* keys below can one of:
  # - nil / empty string to use the built in defaults
  # - A string with the full subject line for this email
  # - A Proc to create the subject line based on the email
  # The subject_prefix will then be applied ontop of these.
  #
  # send_order_receipt_to_buyer: Proc.new { |order| "Order #{order.to_param} has been purchased"}
  # subject_for_subscription_payment_succeeded: Proc.new { |order| "Order #{order.to_param} has been purchased"}

  # subject_for_subscription_trialing: Proc.new { |subscribable| "Pending Order #{order.to_param}"}

  # config.mailer_class_name = 'Effective::OrdersMailer' # One mailer for all tenants

  config.mailer = {
    send_order_receipt_to_admin: true,
    send_order_receipt_to_buyer: true,
    send_payment_request_to_buyer: true,
    send_pending_order_invoice_to_buyer: true,
    send_order_receipts_when_mark_as_paid: false,

    send_subscription_event_to_admin: true,
    send_subscription_created: true,
    send_subscription_updated: true,
    send_subscription_canceled: true,
    send_subscription_payment_succeeded: true,
    send_subscription_payment_failed: true,

    send_subscription_trialing: true,   # Only if you schedule the rake task to run
    send_subscription_trial_expired: true,    # Only if you schedule the rake task to run

    subject_prefix: '[TEST]',

    # Procs yield an Effective::Order object
    subject_for_order_receipt_to_admin: '',
    subject_for_order_receipt_to_buyer: '',
    subject_for_payment_request_to_buyer: '',
    subject_for_pending_order_invoice_to_buyer: '',
    subject_for_refund_notification_to_admin: '',

    # Procs yield an Effective::Customer object
    subject_for_subscription_created: '',
    subject_for_subscription_updated: '',
    subject_for_subscription_canceled: '',
    subject_for_subscription_payment_succeeded: '',
    subject_for_subscription_payment_failed: '',

    # Procs yield the acts_as_subscribable object
    subject_for_subscription_trialing: '',
    subject_for_subscription_trial_expired: '',

    layout: 'effective_orders_mailer_layout',

    default_from: 'no-reply@effective.test',
    admin_email: 'admin@effective.test',   # Refund notifications will also be sent here

    deliver_method: nil  # When nil, will use deliver_later if active_job is configured, otherwise deliver_now
  }

end
