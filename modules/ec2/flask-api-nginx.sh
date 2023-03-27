#!/bin/bash

# Update system packages
sudo yum update -y

# Install necessary packages
sudo amazon-linux-extras install -y nginx1.12 python3.8

# Install Flask and Gunicorn
sudo pip3 install flask gunicorn

# Create a new directory for the Flask app
sudo mkdir /var/www/myapp
cd /var/www/myapp

# Create a virtual environment and activate it
sudo python3 -m venv venv
source venv/bin/activate

# Install Flask app dependencies
sudo pip3 install flask

# Write Flask app code to a file named "app.py"
echo "from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run()" > app.py

# Run the app using Gunicorn
gunicorn app:app --bind 0.0.0.0:8080 &

sudo nano /etc/nginx/sites-available/yoyo

# Configure Nginx
sudo echo "server {
        listen 80;
        server_name yoyo;

        location / {
            proxy_pass http://localhost:8080;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }" > /etc/nginx/conf.d/app.conf

sudo mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled

# Restart Nginx
sudo systemctl enable nginx
sudo systemctl start nginx