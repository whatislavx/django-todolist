import sys
import os
import time
import mysql.connector

hosts = os.environ.get("MYSQL_HOSTS", "").split(",")

user = os.environ.get("DB_USER") or os.environ.get("DATABASE_USER") or os.environ.get("MYSQL_USER")
password = os.environ.get("DB_PASSWORD") or os.environ.get("DATABASE_PASSWORD") or os.environ.get("MYSQL_PASSWORD")
database = os.environ.get("DB_NAME") or os.environ.get("DATABASE_NAME") or os.environ.get("MYSQL_DATABASE")

if not all([user, password, database, hosts]):
    print("Error: Missing database configuration environment variables.", flush=True)
    sys.exit(1)

while True:
    all_ok = True
    for host in hosts:
        if not host.strip():
            continue
        try:
            conn = mysql.connector.connect(
                host=host.strip(), user=user, password=password,
                database=database, connection_timeout=3
            )
            cursor = conn.cursor()
            cursor.execute("SHOW TABLES LIKE 'django_session';")
            result = cursor.fetchone()
            cursor.close()
            conn.close()
            
            if result:
                print(f"Database and migrations OK on host: {host}", flush=True)
            else:
                print(f"Database connected, but migrations/replication NOT YET READY on host: {host}", flush=True)
                all_ok = False
        except Exception as e:
            print(f"Database NOT RESPONDING ({host}): {e}", flush=True)
            all_ok = False
            
    if all_ok:
        print("All database hosts and replicas are fully synchronized!", flush=True)
        sys.exit(0)
        
    print("Waiting for replication to catch up. Retrying in 5s...", flush=True)
    time.sleep(5)