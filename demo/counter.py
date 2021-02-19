import time
import os
import sys
import psycopg2
from psycopg2 import OperationalError, errorcodes, errors

def print_exception(err):
    print(f"psycopg2 ERROR: {err}")
    print(f"extension diagnostics: {err.diag}")
    print(f"pgerror: {err.pgerror}")
    print(f"pgcode: {err.pgcode}\n")

def create_counter(conn):
    with conn.cursor() as cur:
        cur.execute(
            "CREATE TABLE IF NOT EXISTS counter (id SERIAL PRIMARY KEY, value INT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())"
            )
    conn.commit()

def reset_table(conn):
    with conn.cursor() as cur:
        cur.execute("DELETE FROM counter;")
    conn.commit()

def insert_value(value, conn):
    try:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO counter (value) VALUES (%s)", (value,))
    except AttributeError as err:
        raise

def get_connection(conn_str):
    try: 
        conn = psycopg2.connect(conn_str, connect_timeout=1)
    except OperationalError as err:
        # print(f"pgerror: {err}")
        conn = None

    return conn


def main():
    provider = sys.argv[1].lower()
    ip = sys.argv[2]
    connection_string = f"postgresql://root@{ip}:26257/postgres?sslmode=disable"
    print(f"Connecting to {provider}")

    db = get_connection(connection_string)

    if (db is None):
        print(f"ERROR: Can't connect to {provider} using dsn: {connection_string}")
        exit()

    if (provider == "hetzner"):
        create_counter(db)
        reset_table(db)

    provider_id = 0 if provider == "hetzner" else 1

    for x in range(provider_id, 1000, 2):

        while db is None:
            print(f"Lost connection to {provider}. Retrying...")
            db = get_connection(connection_string)
            time.sleep(3)

        # we are sure to have a connection here
        try: 
            insert_value(x, db)
            print(f"Inserted {x} into {provider}")
            time.sleep(1)
        except psycopg2.OperationalError as err:
            # print_exception(err)
            print(f"operational error {err}")
            db = get_connection(connection_string)
        except AttributeError as err:
            print(f"FAILED to insert {x} into {provider}")
            db = get_connection(connection_string)
        except Exception as err:
            print(f"Generic exception {err}")
                

if __name__ == "__main__":
    main()
