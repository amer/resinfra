import time
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
    conn = psycopg2.connect("postgresql://root@127.0.0.1:26257/postgres?sslmode=disable")
    conn2 = psycopg2.connect("postgresql://root@127.0.0.1:26258/postgres?sslmode=disable")

    create_counter(conn)
    reset_table(conn)

    for x in range(1000):
        if x % 2 == 0:
            print(x, "even")
            insert_value(x, conn)
            time.sleep(1)
        else:
            print(x, "odd")
            insert_value(x, conn2)
            time.sleep(1)

if __name__ == "__main__":
    main()

