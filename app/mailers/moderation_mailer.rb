# Sends branded emails when a user is approved or rejected by an admin.
# Also notifies the originating office when their invitation is moderated.
class ModerationMailer < ApplicationMailer
  SPANISH_COUNTRIES = InvitationMailer::SPANISH_COUNTRIES
  PORTUGUESE_COUNTRIES = InvitationMailer::PORTUGUESE_COUNTRIES

  TRANSLATIONS = {
    "en" => {
      approved_subject: "Your HUMANA account has been approved",
      approved_eyebrow: "ACCOUNT APPROVED",
      approved_title: "Welcome to the HUMANA network!",
      approved_body: "Your account has been reviewed and approved. You can now access the platform and start managing your profile.",
      approved_cta: "ACCESS PLATFORM",
      rejected_subject: "Update on your HUMANA application",
      rejected_eyebrow: "APPLICATION UPDATE",
      rejected_title: "Your application was not approved.",
      rejected_body: "After careful review, we were unable to approve your application at this time.",
      rejected_reason_label: "Reason",
      rejected_contact: "If you have questions, please contact us at support@humana.global.",
      office_subject: "Invitation moderated",
      office_eyebrow: "MODERATION UPDATE",
      office_approved_title: "An invitation you sent has been approved.",
      office_rejected_title: "An invitation you sent was not approved.",
      office_rejected_instruction: "Please delete this user from your network and send a new invitation once the necessary corrections have been made.",
      office_user_label: "User",
      office_decision_label: "Decision",
      office_decision_approved: "Approved",
      office_decision_rejected: "Rejected",
      feedback_subject: "Feedback on your HUMANA listing",
      feedback_eyebrow: "LISTING REVIEW",
      feedback_title: "We have feedback on your listing.",
      feedback_body: "The HUMANA team has reviewed your listing and has some comments for you to address before it can be approved.",
      feedback_comments_label: "Comments",
      feedback_note: "Please update your listing accordingly. The admin team will review the changes and approve your listing once everything is in order.",
      suspended_subject: "Your HUMANA account has been suspended",
      suspended_eyebrow: "ACCOUNT SUSPENDED",
      suspended_title: "Your account has been suspended.",
      suspended_body: "Your HUMANA account has been temporarily suspended by the platform administration. During this time, you will not be able to access the platform.",
      suspended_contact: "If you believe this is an error or need more information, please contact our support team.",
      reactivated_subject: "Your HUMANA account has been reactivated",
      reactivated_eyebrow: "ACCOUNT REACTIVATED",
      reactivated_title: "Welcome back to HUMANA!",
      reactivated_body: "Your account has been reactivated. You can now access the platform again with all your previous data intact.",
      reactivated_cta: "ACCESS PLATFORM",
      footer_brand: "HUMANA Global · Wellness Tourism Network",
    },
    "es" => {
      approved_subject: "Tu cuenta HUMANA ha sido aprobada",
      approved_eyebrow: "CUENTA APROBADA",
      approved_title: "Bienvenido a la red HUMANA!",
      approved_body: "Tu cuenta ha sido revisada y aprobada. Ya puedes acceder a la plataforma y comenzar a gestionar tu perfil.",
      approved_cta: "ACCEDER A LA PLATAFORMA",
      rejected_subject: "Actualización sobre tu solicitud en HUMANA",
      rejected_eyebrow: "ACTUALIZACIÓN",
      rejected_title: "Tu solicitud no fue aprobada.",
      rejected_body: "Después de una revisión cuidadosa, no pudimos aprobar tu solicitud en este momento.",
      rejected_reason_label: "Motivo",
      rejected_contact: "Si tienes preguntas, contáctanos en support@humana.global.",
      office_subject: "Invitación moderada",
      office_eyebrow: "ACTUALIZACIÓN DE MODERACIÓN",
      office_approved_title: "Una invitación que enviaste ha sido aprobada.",
      office_rejected_title: "Una invitación que enviaste no fue aprobada.",
      office_rejected_instruction: "Por favor, elimina este usuario de tu red y envía una nueva invitación una vez que se hayan realizado las correcciones necesarias.",
      office_user_label: "Usuario",
      office_decision_label: "Decisión",
      office_decision_approved: "Aprobada",
      office_decision_rejected: "Rechazada",
      feedback_subject: "Comentarios sobre tu publicación en HUMANA",
      feedback_eyebrow: "REVISIÓN DE PUBLICACIÓN",
      feedback_title: "Tenemos comentarios sobre tu publicación.",
      feedback_body: "El equipo de HUMANA ha revisado tu publicación y tiene algunos comentarios que debes atender antes de que pueda ser aprobada.",
      feedback_comments_label: "Comentarios",
      feedback_note: "Por favor, actualiza tu publicación de acuerdo a estos comentarios. El equipo de administración revisará los cambios y aprobará tu publicación cuando todo esté en orden.",
      suspended_subject: "Tu cuenta HUMANA ha sido suspendida",
      suspended_eyebrow: "CUENTA SUSPENDIDA",
      suspended_title: "Tu cuenta ha sido suspendida.",
      suspended_body: "Tu cuenta HUMANA ha sido suspendida temporalmente por la administración de la plataforma. Durante este tiempo, no podrás acceder a la plataforma.",
      suspended_contact: "Si crees que esto es un error o necesitas más información, contacta a nuestro equipo de soporte.",
      reactivated_subject: "Tu cuenta HUMANA ha sido reactivada",
      reactivated_eyebrow: "CUENTA REACTIVADA",
      reactivated_title: "¡Bienvenido de vuelta a HUMANA!",
      reactivated_body: "Tu cuenta ha sido reactivada. Ya puedes acceder a la plataforma nuevamente con todos tus datos previos intactos.",
      reactivated_cta: "ACCEDER A LA PLATAFORMA",
      footer_brand: "HUMANA Global · Red de Turismo de Bienestar",
    },
    "pt" => {
      approved_subject: "Sua conta HUMANA foi aprovada",
      approved_eyebrow: "CONTA APROVADA",
      approved_title: "Bem-vindo à rede HUMANA!",
      approved_body: "Sua conta foi revisada e aprovada. Você já pode acessar a plataforma e começar a gerenciar seu perfil.",
      approved_cta: "ACESSAR PLATAFORMA",
      rejected_subject: "Atualização sobre sua candidatura na HUMANA",
      rejected_eyebrow: "ATUALIZAÇÃO",
      rejected_title: "Sua candidatura não foi aprovada.",
      rejected_body: "Após uma análise cuidadosa, não foi possível aprovar sua candidatura neste momento.",
      rejected_reason_label: "Motivo",
      rejected_contact: "Se tiver dúvidas, entre em contato conosco em support@humana.global.",
      office_subject: "Convite moderado",
      office_eyebrow: "ATUALIZAÇÃO DE MODERAÇÃO",
      office_approved_title: "Um convite que você enviou foi aprovado.",
      office_rejected_title: "Um convite que você enviou não foi aprovado.",
      office_rejected_instruction: "Por favor, exclua este usuário da sua rede e envie um novo convite depois que as correções necessárias forem feitas.",
      office_user_label: "Usuário",
      office_decision_label: "Decisão",
      office_decision_approved: "Aprovado",
      office_decision_rejected: "Rejeitado",
      feedback_subject: "Feedback sobre sua publicação na HUMANA",
      feedback_eyebrow: "REVISÃO DE PUBLICAÇÃO",
      feedback_title: "Temos feedback sobre sua publicação.",
      feedback_body: "A equipe da HUMANA revisou sua publicação e tem alguns comentários que precisam ser atendidos antes que ela possa ser aprovada.",
      feedback_comments_label: "Comentários",
      feedback_note: "Por favor, atualize sua publicação de acordo com estes comentários. A equipe de administração revisará as mudanças e aprovará sua publicação quando tudo estiver em ordem.",
      suspended_subject: "Sua conta HUMANA foi suspensa",
      suspended_eyebrow: "CONTA SUSPENSA",
      suspended_title: "Sua conta foi suspensa.",
      suspended_body: "Sua conta HUMANA foi temporariamente suspensa pela administração da plataforma. Durante este período, você não poderá acessar a plataforma.",
      suspended_contact: "Se você acredita que isso é um erro ou precisa de mais informações, entre em contato com nossa equipe de suporte.",
      reactivated_subject: "Sua conta HUMANA foi reativada",
      reactivated_eyebrow: "CONTA REATIVADA",
      reactivated_title: "Bem-vindo de volta à HUMANA!",
      reactivated_body: "Sua conta foi reativada. Você já pode acessar a plataforma novamente com todos os seus dados anteriores intactos.",
      reactivated_cta: "ACESSAR PLATAFORMA",
      footer_brand: "HUMANA Global · Rede de Turismo de Bem-estar",
    },
  }.freeze

  # Email sent to a user whose account has been approved.
  def approved(user)
    @user = user
    @locale = locale_for(user.organization)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]
    @login_url = "#{ENV.fetch('HUMANA_WEB_URL', 'https://app.humana.global')}/"

    attach_logo
    mail(to: user.email, subject: "✅ #{@t[:approved_subject]}")
  end

  # Email sent to a user whose application was rejected.
  def rejected(user, reason)
    @user = user
    @reason = reason
    @locale = locale_for(user.organization)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]

    attach_logo
    mail(to: user.email, subject: @t[:rejected_subject])
  end

  # Email sent to a hotel with admin feedback — does NOT reject or change status.
  def feedback(user, message)
    @user = user
    @message = message
    @locale = locale_for(user.organization)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]

    attach_logo
    mail(to: user.email, subject: @t[:feedback_subject])
  end

  # Email sent to a user whose account has been suspended.
  def suspended(user)
    @user = user
    @locale = locale_for(user.organization)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]

    attach_logo
    mail(to: user.email, subject: "⚠️ #{@t[:suspended_subject]}")
  end

  # Email sent to a user whose account has been reactivated.
  def reactivated(user)
    @user = user
    @locale = locale_for(user.organization)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]
    @login_url = "#{ENV.fetch('HUMANA_WEB_URL', 'https://app.humana.global')}/"

    attach_logo
    mail(to: user.email, subject: "✅ #{@t[:reactivated_subject]}")
  end

  # Notifies the office that originally invited a user about the moderation decision.
  def office_notification(user, decision, reason = nil)
    invitation = Invitation.where(email: user.email).order(created_at: :desc).first
    return unless invitation&.invited_by&.organization&.office?

    @user = user
    @decision = decision # "approved" or "rejected"
    @reason = reason
    @office_org = invitation.invited_by.organization
    @locale = locale_for(@office_org)
    @t = TRANSLATIONS[@locale] || TRANSLATIONS["en"]

    recipients = User.where(organization: @office_org).pluck(:email)
    return if recipients.empty?

    attach_logo
    mail(to: recipients, subject: "#{@t[:office_subject]} — #{user.name}")
  end

  private

  def locale_for(organization)
    return "en" unless organization
    code = organization.country_code.to_s.upcase
    if SPANISH_COUNTRIES.include?(code)
      "es"
    elsif PORTUGUESE_COUNTRIES.include?(code)
      "pt"
    else
      "en"
    end
  end

  def attach_logo
    logo_path = Rails.root.join("app/assets/images/humana-logo-email.png")
    attachments.inline["humana-logo.png"] = File.read(logo_path)
  end
end
