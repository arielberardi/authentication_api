class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.email[:username]
  layout 'mailer'
end
