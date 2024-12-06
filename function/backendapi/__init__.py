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

    db_host = "{tmp_db_server_name}.postgres.database.azure.com"
    db_name = "{tmp_db_name}"
    db_user = "{tmp_db_server_user}"
    db_password = "{tmp_db_server_password}"
    sendgrid_api_key = "{tmp_sender_api}"
    
    connection = None

    try:
        connection = psycopg2.connect(host=db_host,database=db_name,user=db_user,password=db_password)
        cursor = connection.cursor()

        cursor.execute("SELECT subject, message FROM notification WHERE id = %s",(notification_id,))
        notification = cursor.fetchone()
        
        if not notification:
            logging.error(f"No notification found with ID {notification_id}")
            return

        subject, message = notification

        cursor.execute("SELECT first_name, email FROM attendee")
        attendees = cursor.fetchall()

        for name, email in attendees:
            email_subject = '{}: {}'.format(name, subject)
            mailmessage = Mail(from_email='drwkwcareer@gmail.com',to_emails=email,subject=email_subject,plain_text_content=message)
            try:
                sg = SendGridAPIClient(sendgrid_api_key)
                response = sg.send(mailmessage)
            except Exception as e:
                logging.error(f"An error occurred: {e}")

        completed_date = datetime.utcnow()
        cursor.execute(
            """
            UPDATE notification SET status = %s, completed_date = %s WHERE id = %s
            """,('Notified {} attendees'.format(len(attendees)), completed_date, notification_id)
        )
        connection.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logging.error(f"An error occurred: {error}")
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
