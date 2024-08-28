import enum
import json
import logging
import os
import time

import requests
import errors

LOG = logging.getLogger(__name__)

class BroAgentApi:
    """This is the class to allow easy interaction with a call a bro api."""

    class HttpMethod(enum.Enum):
        """This is the class to allow easy set HTTP method in request call of bro agent api."""

        GET = 1
        POST = 2

    def __init__(self, edca_host, username, password, backup_name):
        """The constructor."""
        self.action = ''
        self.token = ''
        self.edca_host = edca_host
        self.username = username
        self.password = password
        self.backup_name = backup_name
        requests.packages.urllib3.disable_warnings()

    def create_backup(self):
        """Create backup public function."""
        self.action = 'CREATE_BACKUP'
        self.__run_command()

    def delete_backup(self):
        """Delete backup public function."""
        self.action = 'DELETE_BACKUP'
        self.__run_command()

    def restore_backup(self):
        """Restore backup public function."""
        self.action = 'RESTORE'
        try:
            self.__run_command()
            LOG.info('Please wait for the system to fully resume.')
        except errors.BroAgentActionProgressError as exception:
            raise errors.BroAgentActionProgressError(exception)

    def __run_command(self):
        data = self.__generate_backup_payload()
        status, failure_message = self.__do_action(data)
        if failure_message is not None and status == 'FAILURE':
            LOG.info('Failed to %s backup <%s>. Failure reason: %s', self.action, self.backup_name, failure_message)
            raise errors.BroAgentActionProgressError(failure_message)
        LOG.info('%s <%s> success', self.action, self.backup_name)

    def view_backups(self):
        """View list of available backups on the server public function."""
        self.action = 'VIEW'
        self.__print_action_title()
        self.__set_token()
        self.__health_check()
        url = self.edca_host + '/backup-restore/v1/backup-manager/DEFAULT/backup'
        _, response_json = self.__call_bur_rest_api(url=url)
        backups = response_json['backups']
        LOG.info('Available backups:')
        tbl_template = '{NAME:40}{STATUS:15}{CREATION_TIME:25}'
        print(tbl_template.format(
            NAME="NAME", STATUS="STATUS", CREATION_TIME="CREATION-TIME"
        ))
        for record in backups:
            print(tbl_template.format(
                NAME=record['name'], STATUS=record['status'], CREATION_TIME=record['creationTime']
            ))

    def __do_action(self, data=None):
        """Common executor for backup action."""
        self.__print_action_title()
        self.__set_token()
        self.__health_check()
        url = self.edca_host + '/backup-restore/v1/backup-manager/DEFAULT/action'
        status_code, response_json = self.__call_bur_rest_api(url=url,
                                                              http_method=self.HttpMethod.POST,
                                                              data=data)
        if status_code not in (201, 200):
            raise errors.BroAgentActionError('Could Not Complete {}. Reason: {}'.
                                             format(self.action, response_json['message']))

        backup_id = response_json['id']
        LOG.info('---------------------------------------------')
        LOG.info('%s started with action ID: %s', self.action, backup_id)
        LOG.info('---------------------------------------------')
        check_complete_action_url = url + '/' + backup_id
        return self.__show_progress_bar_action(url=check_complete_action_url)

    def __generate_backup_payload(self):
        """Generator JSON body for action HTTP request by BRO agent."""
        payload = {'backupName': self.backup_name}
        data = {'action': self.action, 'payload': payload}
        LOG.debug('called generate_create_backup_payload: data=%s', data)
        return json.dumps(data)

    def __show_progress_bar_action(self, url):
        """Show up progress bar of executing of specific action."""
        LOG.debug('show_progress_bar_action params: action=%s;url=%s;token=%s', self.action, url, self.token)
        status = None
        failure_message = None
        errors_during_process = 0
        attempts = int(os.getenv(key='DM_PROGRESS_ATTEMPTS', default='240'))
        timeout = int(os.getenv(key='DM_PROGRESS_TIMEOUT', default='5'))
        LOG.debug('show_progress_bar_action: DM_PROGRESS_ATTEMPTS = %d; DM_PROGRESS_TIMEOUT = %d', attempts, timeout)
        while status is None or 'NOT_AVAILABLE' in status:
            status_code, agent_response = self.__call_bur_rest_api(url=url)
            LOG.debug('show_progress_bar_action: status_code=%d; agent_response=%s',
                      status_code, agent_response)
            if status_code == 200:
                # reset amount of errors during process if we get success response
                errors_during_process = 0
                status = agent_response['result']
                state = agent_response['state']
                percent_complete = agent_response['progressPercentage']
                LOG.info('State %s. Action %s completion: %d%%', state, self.action, int(percent_complete * 100))
                if 'FINISHED' in state:
                    break
            else:
                errors_during_process += 1
                LOG.debug('show_progress_bar_action: response code: %s; response: %s; error num: %s',
                          status_code, agent_response, errors_during_process)
                if errors_during_process == attempts:
                    failure_message = 'response code: {}; response: {}'.\
                        format(status_code, agent_response)
                    break
            time.sleep(timeout)

        if 'FAILURE' in status:
            if 'additionalInfo' in agent_response:
                failure_message = agent_response['additionalInfo']
            elif 'resultInfo' in agent_response:
                failure_message = agent_response['resultInfo']
            else:
                failure_message = 'unknown error'

        return status, failure_message

    def __print_action_title(self):
        """Show up of title executing action."""
        LOG.info('=====================================================')
        LOG.info('              %s BACKUP MODE', self.action)
        LOG.info('=====================================================')

    def __set_token(self):
        """Authorisation on IDAM server and getting JWT."""
        headers = {'content-type': 'application/json',
                   'X-Login': self.username,
                   'X-Password': self.password}
        url = self.edca_host + '/auth/v1'
        status_code, response = self.__call_bur_rest_api(url=url, http_method=self.HttpMethod.POST, headers=headers)
        LOG.debug("get_token response=%s, status_code=%d", response, status_code)

        if status_code == 200:
            self.token = response
            return
        if 'message' in response:
            raise errors.BroAgentApiGetTokenError(response["message"])

        raise errors.BroAgentApiGetTokenError('Unknown error: response:{}, response code: {}'.
                                              format(response, status_code))

    def __health_check(self):
        """Health checker of BRO agent."""
        LOG.info('Health checking Backup services availability')
        url = self.edca_host + '/backup-restore/v1/health'
        _, response_json = self.__call_bur_rest_api(url=url)
        LOG.debug("health_check response=%s", response_json)
        if 'Access denied' in response_json:
            raise errors.BroAgentHealthCheckAccessDeniedError('Access Denied. Please contact the administrator.')
        availability = response_json["availability"]
        agent_registered = response_json["registeredAgents"]
        if 'Available' not in availability:
            raise errors.BroAgentBackupAvailableError('Backup unavailable, please try again in a few moments')
        LOG.info('Backup Service status is %s -- Continuing with %s', availability, self.action)
        LOG.info('[ %s ] that will be %s', ', '.join(agent_registered), self.action)


    def __call_bur_rest_api(self, url, http_method=HttpMethod.GET, data=None, headers=None):
        """Generic handler http/https call."""
        if self.token is not None and self.token != '':
            final_headers = {'content-type': 'application/json',
                             'Cookie': 'JSESSIONID=' + self.token}
        else:
            final_headers = headers

        try:
            if http_method == self.HttpMethod.GET:
                response = requests.get(url=url, headers=final_headers, data=data, verify=False)
            elif http_method == self.HttpMethod.POST:
                response = requests.post(url=url, headers=final_headers, data=data, verify=False)
        except requests.exceptions.RequestException as err:
            raise requests.exceptions.RequestException('Cannot make a request to Backup and Restore agent.', err)

        try:
            result = json.loads(response.text)
        except ValueError:
            result = response.text
        LOG.debug("__call_bur_rest_api: status_code=%d, response=%s", response.status_code, result)
        return response.status_code, result