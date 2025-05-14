#!/bin/bash

# ========== CONFIG ==========
USERNAME="webuser1"
PASSWORD="StrongPass456"
FULLNAME="John Doe"
EMAIL="admin@example.com"

# ========== ADD USER ==========
/usr/local/hestia/bin/v-add-user $USERNAME "$PASSWORD" "$FULLNAME" "$EMAIL"

echo "✅ Hestia user '$USERNAME' added successfully."