import time
import os
import psycopg2
from psycopg2.errors import SerializationFailure


def main():
    hetznerdb = psycopg2.connect(os.environ['HETZNERDB'])
    gcpdb = psycopg2.connect(os.environ['GCPDB'])
    query = "SELECT value FROM counter"

    while True:
        cur = hetznerdb.cursor()
        cur2 = gcpdb.cursor()
        cur.execute(query)
        cur2.execute(query)
        hetzner = [r[0] for r in cur.fetchall()]
        gcp = [r[0] for r in cur2.fetchall()]
        hetznerdb.commit()
        gcpdb.commit()
        print(f"Hetzner:\n{hetzner}")
        print(f"GCP:\n{gcp}")
        time.sleep(1)

if __name__ == "__main__":
    main()

