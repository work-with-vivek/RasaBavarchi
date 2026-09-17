import smtplib
from email.message import EmailMessage

from app.core.config import settings


def send_email(
    recipient: str,
    subject: str,
    body: str,
) -> None:
    message = EmailMessage()

    message["From"] = f"{settings.smtp_from_name} <{settings.smtp_from_email}>"
    message["To"] = recipient
    message["Subject"] = subject

    message.set_content(body)

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
        server.starttls()
        server.login(
            settings.smtp_username,
            settings.smtp_password,
        )
        server.send_message(message)