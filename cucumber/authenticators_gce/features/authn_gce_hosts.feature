Feature: GCP Authenticator - Test hosts can authentication scenarios

  In this feature we define GCE authenticator in policy, test with different
  host configurations and perform authentication with Conjur.

  Background:
    Given a policy:
    """
    - !policy
      id: conjur/authn-gce
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I have host "test-app"
    And I obtain a valid GCE identity token
    And I grant group "conjur/authn-gce/apps" to host "test-app"


  Scenario: Host with all valid annotations except for project-id is denied
    Given I set invalid "authn-gce/project-id" annotation to host "test-app"
    And I set "authn-gce/service-account-id" annotation to host "test-app"
    And I set "authn-gce/service-account-email" annotation to host "test-app"
    And I set "authn-gce/instance-name" annotation to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gce/project-id' does not match resource in JWT token
    """

  Scenario: Host with all valid annotations except for instance-name is denied
    Given I set invalid "authn-gce/instance-name" annotation to host "test-app"
    And I set "authn-gce/project-id" annotation to host "test-app"
    And I set "authn-gce/service-account-id" annotation to host "test-app"
    And I set "authn-gce/service-account-email" annotation to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gce/instance-name' does not match resource in JWT token
    """

  Scenario: Host with all valid annotations except for service-account-email is denied
    Given I set invalid "authn-gce/service-account-email" annotation to host "test-app"
    And I set "authn-gce/project-id" annotation to host "test-app"
    And I set "authn-gce/service-account-id" annotation to host "test-app"
    And I set "authn-gce/instance-name" annotation to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gce/service-account-email' does not match resource in JWT token
    """

  Scenario: Host with all valid annotations except for service-account-id is denied
    Given I set invalid "authn-gce/service-account-id" annotation to host "test-app"
    And I set "authn-gce/project-id" annotation to host "test-app"
    And I set "authn-gce/service-account-email" annotation to host "test-app"
    And I set "authn-gce/instance-name" annotation to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'authn-gce/service-account-id' does not match resource in JWT token
    """

  Scenario: Host with all valid annotations and an illegal annotation key is denied
    Given I set "authn-gce/invalid-key" annotation to host "test-app"
    And I set all valid GCE annotations to host "test-app"
    And I set "authn-gce/invalid-key" annotation to host "test-app"
    And I save my place in the log file
    When I authenticate with authn-gce using valid token and existing account
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00050E Resource type 'authn-gce/invalid-key' is not a supported resource restriction
    """
