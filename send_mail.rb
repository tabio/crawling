require 'mail'

class SendMail
  class << self
    def send_csv(file_path)
      mail = Mail.new
      options = {
        address: 'smtp.gmail.com',
        port: 587,
        domain: 'smtp.gmail.com',
        user_name: '<username>@gmail.com',
        password: '<password>',
        authentication: :plain,
        enable_starttls_auto: true
      }
      mail.delivery_method :smtp, options

      mail.charset = 'utf-8'
      mail.from 'from@example.com'
      mail.to 'to@example.com'
      mail.subject 'メールタイトル'
      mail.body 'メール本文'
      mail.add_file filename: out_path, content: File.read(file_path)
      mail.deliver
    end
  end
end
