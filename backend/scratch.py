import requests
headers = {"Authorization": "Bearer 123"} # Auth will fail if we just query router without token. 
# Better to query sqlite via python
import sqlite3
import json

conn = sqlite3.connect(r"d:\Vault\backend\vault.db")
c = conn.cursor()
c.execute("SELECT DISTINCT country FROM iptv_cache LIMIT 50")
countries = c.fetchall()
c.execute("SELECT DISTINCT category FROM iptv_cache LIMIT 50")
categories = c.fetchall()
print("Countries:", countries)
print("Categories:", categories)
