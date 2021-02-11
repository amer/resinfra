import time
import psycopg2
from psycopg2.errors import SerializationFailure


def main():
    conn = psycopg2.connect("postgresql://root@127.0.0.1:26257/postgres?sslmode=disable")
    conn2 = psycopg2.connect("postgresql://root@127.0.0.1:26258/postgres?sslmode=disable")
    query = "SELECT value FROM counter"

    while True:
        cur = conn.cursor()
        cur2 = conn2.cursor()
        cur.execute(query)
        cur2.execute(query)
        hetzner = cur.fetchall()
        gcp = cur2.fetchall()
        conn.commit()
        conn2.commit()
        print(f"Hetzner:\n{hetzner}")
        print(f"GCP::\n{gcp}")
        time.sleep(1)

if __name__ == "__main__":
    main()

