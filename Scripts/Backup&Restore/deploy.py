"""The main module for the deploy package."""

import logging
import time
import sys
import re
from datetime import timedelta
import backup_restore_commands
import traceback
from sys import argv
import getpass

LOG = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def create(operation, edca_host, backup_name, username, password):
    """Backup create EDCA."""

    LOG.debug('Input options for backup create command:edca_host=%s;backup_name=%s;',
              edca_host, backup_name)
    start_time = time.time()
    exit_code = 0
    try:
        bro_agent_api = backup_restore_commands.build_bro_agent_api(edca_host=edca_host, username=username, password=password,
                                                                    backup_name=backup_name)
        bro_agent_api.create_backup()

    except Exception as exception:
        LOG.error('EDCA backup create failed with the following error')
        LOG.debug(traceback.format_exc())
        LOG.error(exception)
        exit_code = 1
    else:
       LOG.info('EDCA backup create completed successfully')

    finally:
        end_time = time.time()
        time_taken = end_time - start_time
        LOG.info('Time Taken: %s (%s sec)', timedelta(seconds=round(time_taken)),
                 timedelta(seconds=round(time_taken)).total_seconds())
        sys.exit(exit_code)


def delete(operation, edca_host, backup_name, username, password):
    """Backup delete EDCA."""

    LOG.info('EDCA backup delete started')

    LOG.debug('Input options for backup delete command:edca_host=%s;backup_name=%s;',
              edca_host, backup_name)

    start_time = time.time()
    exit_code = 0
    try:
        bro_agent_api = backup_restore_commands.build_bro_agent_api(edca_host=edca_host, username=username, password=password,
                                                                    backup_name=backup_name)
        bro_agent_api.delete_backup()

    except Exception as exception:
        LOG.error('EDCA backup delete failed with the following error')
        LOG.debug(traceback.format_exc())
        LOG.error(exception)
        exit_code = 1
    else:
        LOG.info('EDCA backup delete completed successfully')
    finally:
        end_time = time.time()
        time_taken = end_time - start_time
        LOG.info('Time Taken: %s (%s sec)', timedelta(seconds=round(time_taken)),
                 timedelta(seconds=round(time_taken)).total_seconds())
        sys.exit(exit_code)


def view(operation, edca_host, username, password):
    """Backup view EDCA."""

    LOG.info('EDCA backup view started')
    LOG.debug('Input options for backup view command:edca_host=%s;', edca_host)

    start_time = time.time()
    exit_code = 0
    try:
        bro_agent_api = backup_restore_commands.build_bro_agent_api(edca_host=edca_host, username=username, password=password)
        bro_agent_api.view_backups()

    except Exception as exception:
        LOG.error('EDCA backup view failed with the following error')
        LOG.debug(traceback.format_exc())
        LOG.error(exception)
        exit_code = 1
    else:
        LOG.info('EDCA backup view completed successfully')
    finally:
        end_time = time.time()
        time_taken = end_time - start_time
        LOG.info('Time Taken: %s (%s sec)', timedelta(seconds=round(time_taken)),
                 timedelta(seconds=round(time_taken)).total_seconds())
        sys.exit(exit_code)


def restore(operation, edca_host, backup_name, username, password):
    """Restore EDCA."""

    LOG.info('EDCA restore started')

    start_time = time.time()
    exit_code = 0
    try:
        bro_agent_api = backup_restore_commands.build_bro_agent_api(edca_host=edca_host, username=username, password=password,
                                                                    backup_name=backup_name)
        bro_agent_api.restore_backup()

    except Exception as exception:
        LOG.error('EDCA restore failed with the following error')
        LOG.debug(traceback.format_exc())
        LOG.error(exception)
        exit_code = 1
    else:
        LOG.info('EDCA restore completed successfully')
    finally:
        end_time = time.time()
        time_taken = end_time - start_time
        LOG.info('Time Taken: %s (%s sec)', timedelta(seconds=round(time_taken)),
              timedelta(seconds=round(time_taken)).total_seconds())
        sys.exit(exit_code)

# input
while True:
  print("Enter Operation to be performed")
  operation = input()
  if (operation.lower() != "create" and operation.lower() != "delete" and operation.lower() != "view" and operation.lower() != "restore"):
   print("Please provide correct value for operation to be performed, For eg: CREATE, DELETE, VIEW, RESTORE")
   continue
  print("Enter EDCA Host")
  edca_host = input()
  print("Enter username")
  username = input()
  print("Enter password")
  password = getpass.getpass()
  if operation.lower() != "view":
   print("Enter BackUp Name")
   backup_name = input()
  break

if operation.lower() == "create":
    create(operation, edca_host, backup_name, username, password)
elif operation.lower() == "delete":
    delete(operation, edca_host, backup_name, username, password)
elif operation.lower() == "view":
    view(operation, edca_host, username, password)
elif operation.lower() == "restore":
    restore(operation, edca_host, backup_name, username, password)