import sqlite3

conn = sqlite3.connect(r'd:\Vault\backend\vault.db')
c = conn.cursor()
try:
    c.execute("ALTER TABLE users ADD COLUMN access_expires_at DATETIME;")
    print("Column added natively.")
except Exception as e:
    print("Error / Already Exists: ", e)
conn.commit()
conn.close()
