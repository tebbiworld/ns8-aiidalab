*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Variables ***
${CONFIG}    {"host":"aiidalab.ci.test","lets_encrypt":false,"http2https":true,"password":"Notebook#Pass 1","aiida_user_email":"ci@ci.test","aiida_user_first_name":"CI","aiida_user_last_name":"User","aiida_user_institution":"CI","default_apps":[],"computer_enabled":false}

*** Test Cases ***
Install the module
    IF    '${SCENARIO}' == 'update'
        ${output}  ${rc} =    Execute Command    add-module ${UPDATE_FROM} 1    return_rc=True
    ELSE
        ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1    return_rc=True
    END
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Configure the module
    Run task    module/${module_id}/configure-module    ${CONFIG}    decode_json=${FALSE}

AiiDAlab answers behind Traefik
    Wait Until Keyword Succeeds    120 times    10 seconds    Login page is served

Update to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    Run on node    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    Wait Until Keyword Succeeds    120 times    10 seconds    Login page is served

Configuration reads back
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    aiidalab.ci.test
    Should Be True    ${cfg['password_set']}

The notebook server still knows the password hash
    ${n} =    Run on node    runagent -m ${module_id} bash -c 'grep -c "hashed_password=.sha1:" "$AGENT_STATE_DIR/aiidalab.env"'
    Should Be Equal As Integers    ${n.strip()}    1

Secrets are stored in passwords.env only
    Secrets are kept out of the module environment    ${module_id}
    ${leaks} =    Run on node    runagent -m ${module_id} bash -c 'grep -c PASSWORD_HASH "$AGENT_STATE_DIR/environment" || true'
    Should Be Equal As Integers    ${leaks.strip()}    0

*** Keywords ***
Login page is served
    ${out} =    Run on node    curl -fsSkL -H 'Host: aiidalab.ci.test' https://127.0.0.1/login
    Should Contain    ${out}    assword
