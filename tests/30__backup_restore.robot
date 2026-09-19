*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Seed a probe file
    Run on node    runagent -m ${module_id} podman exec aiidalab-app sh -c 'echo pre-backup > /home/jovyan/ci_probe.txt'

Back up the module
    ${repo}    ${path} =    Back up the module to the cluster repository    ${module_id}
    Set Global Variable    ${BACKUP_REPO}    ${repo}
    Set Global Variable    ${BACKUP_PATH}    ${path}

Free the memory of the first instance
    Run on node    runagent -m ${module_id} systemctl --user stop aiidalab.service

Restore into a new instance
    ${rid} =    Restore the module from the cluster repository    ${BACKUP_REPO}    ${BACKUP_PATH}
    Set Global Variable    ${restored_id}    ${rid}
    Should Not Be Equal    ${restored_id}    ${module_id}

The restored instance has data, settings and secrets
    ${cfg} =    Run task    module/${restored_id}/get-configuration    {}
    Should Be True    ${cfg['password_set']}
    Secrets are kept out of the module environment    ${restored_id}
    ${a} =    Run on node    runagent -m ${module_id} bash -c 'grep ^PASSWORD_HASH= "$AGENT_STATE_DIR/passwords.env" | sha256sum'
    ${b} =    Run on node    runagent -m ${restored_id} bash -c 'grep ^PASSWORD_HASH= "$AGENT_STATE_DIR/passwords.env" | sha256sum'
    Should Be Equal    ${a}    ${b}
    ${out} =    Wait Until Keyword Succeeds    90 times    10 seconds
    ...    Run on node    runagent -m ${restored_id} podman exec aiidalab-app cat /home/jovyan/ci_probe.txt
    Should Contain    ${out}    pre-backup
