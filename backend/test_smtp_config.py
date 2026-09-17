from app.core.config import settings


print("SMTP host:", settings.smtp_host)
print("SMTP port:", settings.smtp_port)
print("SMTP username:", settings.smtp_username)
print("SMTP from email:", settings.smtp_from_email)
print("SMTP password configured:", bool(settings.smtp_password))
print("SMTP password length:", len(settings.smtp_password))