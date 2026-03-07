import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# --- YOUR GMAIL CREDENTIALS ---
SENDER_EMAIL = "echovision510@gmail.com"  # Replace with your new Gmail
SENDER_PASSWORD = "jahstulniizdhqkh" # Replace with the App Password (no spaces)

def send_verification_email(receiver_email: str, code: str):
    # 1. Setup the Email message
    subject = "Verify your EchoVision Account"
    body = f"""
    Welcome to EchoVision!
    
    Your 6-digit verification code is: {code}
    
    Please enter this code in the app to activate your account.
    """

    msg = MIMEMultipart()
    msg['From'] = SENDER_EMAIL
    msg['To'] = receiver_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    # 2. Connect to Gmail and Send
    try:
        # Connect to Google's SMTP server securely
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls() 
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        
        # Send the email
        server.send_message(msg)
        server.quit()
        print(f"📧 Verification email sent successfully to {receiver_email}")
        return True
    except Exception as e:
        print(f"❌ Failed to send email: {e}")
        return False