#!/bin/bash

echo "==================================================="
echo "  Vault IPTV - Server Startup Script (Raspberry Pi)"
echo "==================================================="

# Detect Current IP Address
IP=$(hostname -I | awk '{print $1}')
echo "Detected Local IP: $IP"

echo ""
echo "==================================================="
echo "  Starting Vault Backend Server..."
echo "  Access Web App at: http://$IP:8000/"
echo "==================================================="

cd backend
# If using a virtual environment, uncomment the following line:
# source venv/bin/activate

uvicorn app.main:app --host 0.0.0.0 --port 8000
