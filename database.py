#!/usr/bin/env python

# Modelled from http://www.postgresqltutorial.com/postgresql-python/connect/

import psycopg2

from utils import log, LogLevel
from config import config

def connect():
    """Connect to the PostgreSQL database server"""
    conn, params = None, None
    try:
        # Read connection parameters
        params = config()

        # Connect to the PostgreSQL server
        log(LogLevel.INFO, "Connecting to database '{database}' on {host}:{port}".format(**params))
        conn = psycopg2.connect(**params)
    except (Exception, psycopg2.DatabaseError) as e:
        log(LogLevel.ERROR, e)
    else:
        if conn:
            log(LogLevel.INFO, "Successfully connected to database '{database}' on {host}:{port}".format(**params))
    finally:
        return conn


def load_lists(json):
    inserted_id = -1
    try:
        # Connect to the database
        conn = connect()
        with conn:
            with conn.cursor() as cur:
                cur.callproc('Staging.LoadJSON', [json])
                ret = cur.fetchone()

                # Check for error
                if not ret[1]:
                    log(LogLevel.INFO, "Successfully loaded JSON data.")
                    inserted_id = ret[0]
                else:
                    log(LogLevel.ERROR, "Could not load JSON -- {0}".format(ret[0]))

        conn.close()

    except (Exception, psycopg2.DatabaseError) as e:
        log(LogLevel.ERROR, e)
    finally:
        return inserted_id
    

if __name__ == '__main__':
    # conn = connect()
    # cur = conn.cursor()
    # cur.execute('SELECT version()')
    # db_version = cur.fetchone()
    # log(LogLevel.INFO, "PostgreSQL database version: {0}".format(db_version))
    # conn.close()

    json = '{"fruit":"raspberry"}'
    load_lists(json)