import logging
import azure.functions as func
import psycopg2
import os
from datetime import datetime
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def main(msg: func.ServiceBusMessage):
    notification_id = int(msg.get_body().decode('utf-8'))
    logging.info('Python ServiceBus queue trigger processed message: %s', notification_id)

    db_host = os.getenv("DB_HOST")
    db_name = os.getenv("DB_NAME")
    db_user = os.getenv("DB_USER")
    db_password = os.getenv("DB_PASSWORD")
    sendgrid_api_key = os.getenv("SENDGRID_API_KEY")

    connection = None

    try:
        connection = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password
        )
        cursor = connection.cursor()

        # Fetch notification details
        cursor.execute(
            "SELECT subject, message FROM notifications WHERE id = %s",
            (notification_id,)
        )
        notification = cursor.fetchone()
        if not notification:
            logging.error(f"No notification found with ID {notification_id}")
            return

        subject, message = notification

        # Fetch all attendees
        cursor.execute("SELECT name, email FROM attendees")
        attendees = cursor.fetchall()

        # Send emails to all attendees
        for name, email in attendees:
            personalized_subject = f"{subject} - Dear {name}"
            send_email(sendgrid_api_key, email, personalized_subject, message)
            logging.info(f"Email sent to {name} ({email})")

        # Update notification table
        completed_date = datetime.utcnow()
        cursor.execute(
            """
            UPDATE notifications
            SET status = %s, completed_date = %s
            WHERE id = %s
            """,
            ('Completed', completed_date, notification_id)
        )
        connection.commit()
        logging.info(f"Notification {notification_id} marked as completed with {len(attendees)} attendees notified.")

    except (Exception, psycopg2.DatabaseError) as error:
        logging.error(f"An error occurred: {error}")
    finally:
        if connection:
            connection.close()


def send_email(api_key, to_email, subject, content):
    """Send email using SendGrid API."""
    message = Mail(
        from_email='your-email@example.com',
        to_emails=to_email,
        subject=subject,
        plain_text_content=content
    )
    try:
        sg = SendGridAPIClient(api_key)
        response = sg.send(message)
        logging.info(f"Email sent with status code {response.status_code}")
    except Exception as e:
        logging.error(f"An error occurred while sending email: {e}")
