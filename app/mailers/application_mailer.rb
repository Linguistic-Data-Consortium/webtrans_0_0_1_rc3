class ApplicationMailer < ActionMailer::Base
  # default from: 'noreply@example.com'
  default from: ENV['GMAIL_USER'] + '@gmail.com'
  layout 'mailer'
end