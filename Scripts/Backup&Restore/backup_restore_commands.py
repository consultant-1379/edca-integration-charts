"""This module contains the logic for the backup and restore commands the user may call from the CLI."""
import bro_agent


def build_bro_agent_api(edca_host, username, password, backup_name=None):
    """Get Bro Agent Api instance."""
    return bro_agent.BroAgentApi(edca_host=edca_host,
                                 username=username,
                                 password=password,
                                 backup_name=backup_name)
