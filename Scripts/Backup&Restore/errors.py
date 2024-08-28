"""This module defines the custom exceptions to be thrown by EDCA Backup & Restore Manager."""


class Error(Exception):
    """The base class for exceptions in EDCA Backup & Restore Manager"""

class BroAgentApiGetTokenError(Error):
    """Exception raised when cannot get token from BroAgent API."""


class BroAgentHealthCheckAccessDeniedError(Error):
    """Exception raised when cannot get access to services on BroAgent API."""


class BroAgentBackupAvailableError(Error):
    """Exception raised when cannot get backups from BroAgent API."""


class BroAgentActionError(Error):
    """Exception raised when cannot complete action on BroAgent API."""


class BroAgentActionProgressError(Error):
    """Exception raised when cannot progress action on BroAgent API."""
