import smtplib

from app.core.config import settings


try:
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as server:
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(
            settings.smtp_username,
            settings.smtp_password,
        )

    print("SUCCESS: Gmail SMTP authentication works.")

except Exception as exc:
    print(f"FAILED: {type(exc).__name__}: {exc}")