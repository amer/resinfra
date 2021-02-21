import time
import sys
import os
import psycopg2


def get_connection(conn_str):
    try: 
        conn = psycopg2.connect(conn_str, connect_timeout=1)
    except psycopg2.OperationalError as err:
        # print(f"error: {err}")
        conn = None

    return conn

def main():
    hetzner_conn = f"postgresql://root@{sys.argv[1]}:26257/postgres?sslmode=disable"
    gcp_conn = f"postgresql://root@{sys.argv[2]}:26257/postgres?sslmode=disable"

    hetznerdb = get_connection(hetzner_conn)
    gcpdb = get_connection(gcp_conn)

    if (hetznerdb is None):
        print(f"No connection to hetznerdb")
        exit()

    if gcpdb is None:
        print(f"No connection to gcpdb")
        exit()

    query = "SELECT value FROM counter ORDER BY created_at DESC LIMIT 10"
    

    while True:
        try:
            cur = hetznerdb.cursor()
            cur.execute(query)
            hetznerdb.commit()
            hetzner = [r[0] for r in cur.fetchall()]
        except (psycopg2.OperationalError,AttributeError) as err:
            hetzner = "Lost connection to hetzner. Retrying...."
            hetznerdb = get_connection(hetzner_conn)
            # print(f"error: {err}")

        try:
            cur2 = gcpdb.cursor()
            cur2.execute(query)
            gcpdb.commit()
            gcp = [r[0] for r in cur2.fetchall()]
        except (psycopg2.OperationalError,AttributeError) as err:
            gcp = "Lost connection to gcp. Retrying...."
            gcpdb = get_connection(gcp_conn)
            # print(f"error: {err}")


        print(f"Hetzner:{hetzner}")
        print(f"GCP:{gcp}")
        time.sleep(1)

if __name__ == "__main__":
    main()
