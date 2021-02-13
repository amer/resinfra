import time
import os
import psycopg2
from psycopg2.errors import SerializationFailure

def create_counter(conn):
    with conn.cursor() as cur:
        cur.execute(
            "CREATE TABLE IF NOT EXISTS counter (id SERIAL PRIMARY KEY, value INT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())"
            )
    conn.commit()

def reset_table(conn):
    with conn.cursor() as cur:
        cur.execute(
                "DELETE FROM counter;"
            )
    conn.commit()

def insert_value(value, conn):
    with conn.cursor() as cur:
        cur.execute("INSERT INTO counter (value) VALUES (%s)", (value,))
    conn.commit()


def main():
    hetznerdb = psycopg2.connect(os.environ['HETZNERDB'])
    gcpdb = psycopg2.connect(os.environ['GCPDB'])

    create_counter(hetznerdb)
    reset_table(hetznerdb)

    for x in range(1000):
        if x % 2 == 0:
            print(f"Insert {x} into hetzner")
            insert_value(x, hetznerdb)
            time.sleep(1)
        else:
            print(f"Insert {x} into gcp")
            insert_value(x, gcpdb)
            time.sleep(1)

if __name__ == "__main__":
    main()
