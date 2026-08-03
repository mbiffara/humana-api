# Sends branded subscription lifecycle emails (confirmed, renewed, cancelled, payment failed).
# Language is determined by the organization owner's locale.
class SubscriptionMailer < ApplicationMailer
  TRANSLATIONS = {
    "en" => {
      confirmed: {
        subject: "Your subscription is active",
        eyebrow: "SUBSCRIPTION CONFIRMED",
        title: "Welcome to your HUMANA plan.",
        greeting: "Hello,",
        body: "Your subscription has been activated successfully. You now have full access to all features included in your plan.",
        plan_label: "Plan",
        amount_label: "Amount",
        period_label: "Next billing date",
        cta: "GO TO DASHBOARD",
        footer_brand: "HUMANA Global \u00b7 Wellness Tourism Network",
        footer_sent: "This email was sent to",
        footer_note: "You're receiving this because you subscribed to a HUMANA plan.",
      },
      renewed: {
        subject: "Your subscription was renewed",
        eyebrow: "SUBSCRIPTION RENEWED",
        title: "Your HUMANA subscription was renewed.",
        greeting: "Hello,",
        body: "Your monthly subscription payment was processed successfully. Your access continues without interruption.",
        plan_label: "Plan",
        amount_label: "Amount charged",
        period_label: "Next billing date",
        cta: "VIEW SUBSCRIPTION",
        footer_brand: "HUMANA Global \u00b7 Wellness Tourism Network",
        footer_sent: "This email was sent to",
        footer_note: "You're receiving this because you have an active HUMANA subscription.",
      },
      cancelled: {
        subject: "Your subscription has been cancelled",
        eyebrow: "SUBSCRIPTION CANCELLED",
        title: "Your HUMANA subscription was cancelled.",
        greeting: "Hello,",
        body: "Your subscription has been cancelled. You can continue using your plan features until the end of your current billing period. After that, access to premium features will be restricted.",
        plan_label: "Plan",
        access_until_label: "Access until",
        cta: "RESUBSCRIBE",
        footer_brand: "HUMANA Global \u00b7 Wellness Tourism Network",
        footer_sent: "This email was sent to",
        footer_note: "You're receiving this because your HUMANA subscription was cancelled.",
      },
      payment_failed: {
        subject: "Payment failed for your subscription",
        eyebrow: "PAYMENT FAILED",
        title: "We couldn\u2019t process your payment.",
        greeting: "Hello,",
        body: "We were unable to process your subscription payment. Please update your payment method to avoid service interruption. Stripe will retry automatically, but if the issue persists, your subscription may be paused.",
        plan_label: "Plan",
        cta: "UPDATE PAYMENT METHOD",
        footer_brand: "HUMANA Global \u00b7 Wellness Tourism Network",
        footer_sent: "This email was sent to",
        footer_note: "You're receiving this because a payment for your HUMANA subscription failed.",
      },
    },
    "es" => {
      confirmed: {
        subject: "Tu suscripci\u00f3n est\u00e1 activa",
        eyebrow: "SUSCRIPCI\u00d3N CONFIRMADA",
        title: "Bienvenido a tu plan HUMANA.",
        greeting: "Hola,",
        body: "Tu suscripci\u00f3n ha sido activada exitosamente. Ahora tienes acceso completo a todas las funciones incluidas en tu plan.",
        plan_label: "Plan",
        amount_label: "Monto",
        period_label: "Pr\u00f3xima fecha de cobro",
        cta: "IR AL PANEL",
        footer_brand: "HUMANA Global \u00b7 Red de Turismo de Bienestar",
        footer_sent: "Este email fue enviado a",
        footer_note: "Recibes esto porque te suscribiste a un plan de HUMANA.",
      },
      renewed: {
        subject: "Tu suscripci\u00f3n fue renovada",
        eyebrow: "SUSCRIPCI\u00d3N RENOVADA",
        title: "Tu suscripci\u00f3n HUMANA fue renovada.",
        greeting: "Hola,",
        body: "Tu pago mensual de suscripci\u00f3n fue procesado exitosamente. Tu acceso contin\u00faa sin interrupciones.",
        plan_label: "Plan",
        amount_label: "Monto cobrado",
        period_label: "Pr\u00f3xima fecha de cobro",
        cta: "VER SUSCRIPCI\u00d3N",
        footer_brand: "HUMANA Global \u00b7 Red de Turismo de Bienestar",
        footer_sent: "Este email fue enviado a",
        footer_note: "Recibes esto porque tienes una suscripci\u00f3n activa en HUMANA.",
      },
      cancelled: {
        subject: "Tu suscripci\u00f3n ha sido cancelada",
        eyebrow: "SUSCRIPCI\u00d3N CANCELADA",
        title: "Tu suscripci\u00f3n HUMANA fue cancelada.",
        greeting: "Hola,",
        body: "Tu suscripci\u00f3n ha sido cancelada. Puedes seguir usando las funciones de tu plan hasta el final de tu per\u00edodo de facturaci\u00f3n actual. Despu\u00e9s, el acceso a funciones premium ser\u00e1 restringido.",
        plan_label: "Plan",
        access_until_label: "Acceso hasta",
        cta: "VOLVER A SUSCRIBIRSE",
        footer_brand: "HUMANA Global \u00b7 Red de Turismo de Bienestar",
        footer_sent: "Este email fue enviado a",
        footer_note: "Recibes esto porque tu suscripci\u00f3n de HUMANA fue cancelada.",
      },
      payment_failed: {
        subject: "Fall\u00f3 el pago de tu suscripci\u00f3n",
        eyebrow: "PAGO FALLIDO",
        title: "No pudimos procesar tu pago.",
        greeting: "Hola,",
        body: "No pudimos procesar el pago de tu suscripci\u00f3n. Por favor actualiza tu m\u00e9todo de pago para evitar la interrupci\u00f3n del servicio. Stripe reintentar\u00e1 autom\u00e1ticamente, pero si el problema persiste, tu suscripci\u00f3n podr\u00eda pausarse.",
        plan_label: "Plan",
        cta: "ACTUALIZAR M\u00c9TODO DE PAGO",
        footer_brand: "HUMANA Global \u00b7 Red de Turismo de Bienestar",
        footer_sent: "Este email fue enviado a",
        footer_note: "Recibes esto porque fall\u00f3 un pago de tu suscripci\u00f3n HUMANA.",
      },
    },
    "pt" => {
      confirmed: {
        subject: "Sua assinatura est\u00e1 ativa",
        eyebrow: "ASSINATURA CONFIRMADA",
        title: "Bem-vindo ao seu plano HUMANA.",
        greeting: "Ol\u00e1,",
        body: "Sua assinatura foi ativada com sucesso. Agora voc\u00ea tem acesso completo a todos os recursos inclu\u00eddos no seu plano.",
        plan_label: "Plano",
        amount_label: "Valor",
        period_label: "Pr\u00f3xima data de cobran\u00e7a",
        cta: "IR AO PAINEL",
        footer_brand: "HUMANA Global \u00b7 Rede de Turismo de Bem-estar",
        footer_sent: "Este email foi enviado para",
        footer_note: "Voc\u00ea recebe isso porque se inscreveu em um plano HUMANA.",
      },
      renewed: {
        subject: "Sua assinatura foi renovada",
        eyebrow: "ASSINATURA RENOVADA",
        title: "Sua assinatura HUMANA foi renovada.",
        greeting: "Ol\u00e1,",
        body: "Seu pagamento mensal de assinatura foi processado com sucesso. Seu acesso continua sem interrup\u00e7\u00f5es.",
        plan_label: "Plano",
        amount_label: "Valor cobrado",
        period_label: "Pr\u00f3xima data de cobran\u00e7a",
        cta: "VER ASSINATURA",
        footer_brand: "HUMANA Global \u00b7 Rede de Turismo de Bem-estar",
        footer_sent: "Este email foi enviado para",
        footer_note: "Voc\u00ea recebe isso porque tem uma assinatura ativa na HUMANA.",
      },
      cancelled: {
        subject: "Sua assinatura foi cancelada",
        eyebrow: "ASSINATURA CANCELADA",
        title: "Sua assinatura HUMANA foi cancelada.",
        greeting: "Ol\u00e1,",
        body: "Sua assinatura foi cancelada. Voc\u00ea pode continuar usando os recursos do seu plano at\u00e9 o final do per\u00edodo de faturamento atual. Depois disso, o acesso a recursos premium ser\u00e1 restrito.",
        plan_label: "Plano",
        access_until_label: "Acesso at\u00e9",
        cta: "REASSINAR",
        footer_brand: "HUMANA Global \u00b7 Rede de Turismo de Bem-estar",
        footer_sent: "Este email foi enviado para",
        footer_note: "Voc\u00ea recebe isso porque sua assinatura HUMANA foi cancelada.",
      },
      payment_failed: {
        subject: "Falha no pagamento da sua assinatura",
        eyebrow: "PAGAMENTO FALHOU",
        title: "N\u00e3o conseguimos processar seu pagamento.",
        greeting: "Ol\u00e1,",
        body: "N\u00e3o foi poss\u00edvel processar o pagamento da sua assinatura. Por favor, atualize seu m\u00e9todo de pagamento para evitar a interrup\u00e7\u00e3o do servi\u00e7o. O Stripe tentar\u00e1 novamente automaticamente, mas se o problema persistir, sua assinatura poder\u00e1 ser pausada.",
        plan_label: "Plano",
        cta: "ATUALIZAR M\u00c9TODO DE PAGAMENTO",
        footer_brand: "HUMANA Global \u00b7 Rede de Turismo de Bem-estar",
        footer_sent: "Este email foi enviado para",
        footer_note: "Voc\u00ea recebe isso porque um pagamento da sua assinatura HUMANA falhou.",
      },
    },
  }.freeze

  def confirmed(subscription)
    setup(subscription, :confirmed)
    @amount = format_amount(subscription)
    @next_billing = subscription.current_period_end&.strftime("%B %d, %Y")
    @cta_url = dashboard_url

    mail(to: recipients, subject: "\u2705 #{@t[:subject]} \u2014 HUMANA")
  end

  def renewed(subscription)
    setup(subscription, :renewed)
    @amount = format_amount(subscription)
    @next_billing = subscription.current_period_end&.strftime("%B %d, %Y")
    @cta_url = settings_url

    mail(to: recipients, subject: "\u2705 #{@t[:subject]} \u2014 HUMANA")
  end

  def cancelled(subscription)
    setup(subscription, :cancelled)
    @access_until = subscription.current_period_end&.strftime("%B %d, %Y")
    @cta_url = settings_url

    mail(to: recipients, subject: "\u274c #{@t[:subject]} \u2014 HUMANA")
  end

  def payment_failed(subscription)
    setup(subscription, :payment_failed)
    @cta_url = settings_url

    mail(to: recipients, subject: "\u26a0\ufe0f #{@t[:subject]} \u2014 HUMANA")
  end

  private

  def setup(subscription, template_key)
    @subscription = subscription
    @organization = subscription.organization
    @plan = subscription.subscription_plan
    @owner = @organization.users.find_by(role: "owner")
    @locale = @owner&.locale || "en"
    @t = TRANSLATIONS.dig(@locale, template_key) || TRANSLATIONS.dig("en", template_key)

    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)
  end

  def recipients
    emails = []
    emails << @organization.contact_email if @organization.contact_email.present?
    emails << @owner.email if @owner&.email.present?
    emails.uniq
  end

  def format_amount(subscription)
    plan = subscription.subscription_plan
    "$#{(plan.price_cents / 100.0).round(0).to_i}/#{plan.billing_interval == 'yearly' ? 'yr' : 'mo'}"
  end

  def dashboard_url
    kind = @organization.kind
    "#{web_url}/#{kind == 'hotel' ? 'hotel/dashboard' : 'dashboard'}"
  end

  def settings_url
    kind = @organization.kind
    "#{web_url}/#{kind}/settings?tab=subscription"
  end

  def web_url
    ENV.fetch("HUMANA_WEB_URL", "http://localhost:3000")
  end
end
