
# Strengthen Longhorn with Automated End-to-End Tests

### Why E2E Testing Matters for Longhorn

E2E testing is a core part of ensuring Longhorn remains stable, resilient, and production-ready. While integration tests validate individual components, E2E tests validate the entire system under real-world conditions; especially automated tests derived from user-reported issues, disruptive operations such as node shutdowns or reboots, and scenarios that may be repeated hundreds of times to uncover stability issues. Automating these scenarios helps the QA team quickly validate every Longhorn release, reducing manual workload and ensuring issues are found early.

### What Is Covered by Our E2E Test Suites

Longhorn maintains two major public automated test suites:
Integration Tests and End-to-End (E2E) Tests.

#### Integration tests ([Source code](https://github.com/longhorn/longhorn-tests/tree/master/manager/integration/), [CI](https://ci.longhorn.io/job/public/job/master/job/sles/job/amd64/job/longhorn-tests-sles-amd64/))

The integration test suite focuses on validating the **core Longhorn functionality**, including:

- Volume lifecycle (create, attach, detach, delete)
- Replica scheduling and rebuilding
- High availability behavior
- Settings validation
- Longhorn upgrades
- Engine version validate

The integration test suite is gradually being deprecated in favor of moving all test cases into the E2E test framework.

#### E2E Tests — Full System Scenarios ([Source code](https://github.com/longhorn/longhorn-tests/tree/master/e2e), [CI](https://ci.longhorn.io/job/public/job/master/job/sles/job/amd64/job/longhorn-e2e-tests-sles-amd64/))

The E2E test suite is written in **Robot Framework** using a BDD-style structure. It focuses on:

- Converting user-reported issues into automated test cases
- Node reboots
- Node power-down
- Network disconnect
- Automating [manual test cases](https://longhorn.github.io/longhorn-tests/manual/) that are executed during release testing

As part of ongoing improvements, integration tests are actively being **migrated into the E2E suite**. The goal is to eventually use one unified test framework. Since E2E tests are written in a BDD-style format, it’s much easier to understand the test steps from the logs and see exactly why a test failed, which greatly helps with debugging.

## Structure of an Automated E2E Test Case

This is how an E2E test flows through the framework:
```
Robot Test Case (.robot) → Robot Keyword (.resource) → Python Backend Logic (_keywords.py)
```

### Test case

[Robot Framework test for recurring backup job interruptions](https://github.com/longhorn/longhorn-tests/blob/master/e2e/tests/negative/recurring_backup_job_interruptions.robot)

```robotframework
*** Test Cases ***
Recurring backup job interruptions when Allow Recurring Job While Volume Is Detached is disabled
    [Documentation]    https://longhorn.github.io/longhorn-tests/manual/release-specific/v1.1.0/recurring-backup-job-interruptions/
    ...                Scenario 1- Allow Recurring Job While Volume Is Detached disabled, attached pod scaled down while the recurring backup was in progress.
    Given Setting allow-recurring-job-while-volume-detached is set to false
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create statefulset 0 using RWO volume with longhorn-test storageclass and size 5 Gi
    And Write 4096 MB data to file data in statefulset 0

    When Create backup recurringjob 0
    ...    groups=["default"]
    ...    cron=*/2 * * * *
    ...    concurrency=1
    ...    labels={"test":"recurringjob"}

    Then Wait for backup recurringjob 0 started
    And Scale statefulset 0 to 0
    And Verify backup list contains backup no error for statefulset 0 volume
    And Wait for statefulset 0 volume detached

    When Sleep    180
    And Verify no new backup created
```

### Resource Keywords

Resource keywords act as reusable building blocks shared across test cases. They:
- Organize related operations (for example, recurring jobs, volumes, workloads)
- Bridge Robot Framework syntax with Python backend functions
- Keep logic centralized and easy to maintain

Example keyword:

```robotframework
*** Settings ***
Documentation    RecurringJob Keywords
Library    Collections
Library    ../libs/keywords/common_keywords.py
Library    ../libs/keywords/recurringjob_keywords.py

*** Keywords ***
Wait for ${job_task} recurringjob ${job_id} started
    ${job_name} =   generate_name_with_suffix    ${job_task}    ${job_id}
    ${job_pod_name} =   wait_for_recurringjob_pod_create    ${job_name}
```

## How to Write an E2E Test Case Using Robot Framework

Longhorn's E2E tests follow a layered design that keeps test cases readable, maintainable, and easy to extend. Each E2E test case is composed of:
- **Readable test steps in Robot Framework**: Human-friendly, BDD-style test definitions written in `*.robot` files.
- **Reusable resource keywords**: Shared keywords that define common operations across many tests.
- **Backend Python libraries**: Python functions that perform Kubernetes and Longhorn API actions.

Example:

```robotframework
*** Test Cases ***
Example test
    Given Setting example-setting is set to false
    And Create statefulset 0 using RWO volume
    When Perform some operation
    Then Verify expected result
```

This structure allows contributors to write tests in a clean, readable format while relying on shared keywords and Python functions in the backend.

#### 1. Write or extend a robot test case

Write readable, BDD-style steps:

```
When Create backup recurringjob 0
...
Then Wait for backup recurringjob 0 started
```

#### 2. If the keyword does not exist, define it in a `.resource` file

Place the keyword in a resource file that matches the feature area (for example, `recurringjob.resource`):

```
Wait for ${job_task} recurringjob ${job_id} started
    ${job_name} =   generate_name_with_suffix    ${job_task}    ${job_id}
    ${job_pod_name} =   wait_for_recurringjob_pod_create    ${job_name}
```

#### 3. Implement backend logic in Python only when necessary

Implement backend logic in Python when there is no existing keyword or library that you can reuse.

Example:

```
# e2e/libs/keywords/recurringjob_keywords.py
def wait_for_recurringjob_pod_create(self, job_name):
    logging(f'Waiting for recurringjob {job_name} pod start')
    start_time = datetime.now(timezone.utc)
    retry_count, retry_interval = get_retry_count_and_interval()
    for i in range(retry_count):
        pods = list_namespaced_pod("longhorn-system", f"recurring-job.longhorn.io={job_name}")
        for pod in pods:
            if pod.metadata.creation_timestamp and pod.metadata.creation_timestamp > start_time:
                logging(f"Pod {pod.metadata.name} created at {pod.metadata.creation_timestamp}")
                return
        time.sleep(retry_interval)
    assert False, f"No new pod of {job_name} is created after {start_time}"
```

The function monitors Longhorn recurring job pods using the label `recurring-job.longhorn.io={job_name}`.

#### 4. Reuse as much as possible

Many common operations already exist and should be reused:

```
e2e/libs/keywords/common_keywords.py
e2e/libs/keywords/*_keywords.py
e2e/keywords/*.resource
```

#### 5. Robot → Resource → Python Flow

```
longhorn-tests/e2e/tests/negative/recurring_backup_job_interruptions.robot
└─ calls →  Wait for backup recurringjob 0 started
        (Robot test case step)
```
```
longhorn-tests/e2e/keywords/recurringjob.resource
├─ imports →  Library  longhorn-tests/e2e/libs/keywords/recurringjob_keywords.py
└─ defines →  Wait for ${job_task} recurringjob ${job_id} started
        (Keyword define calls Python)
```
```
longhorn-tests/e2e/libs/keywords/recurringjob_keywords.py
└─ implements →  wait_for_recurringjob_pod_create
        (Python function that waits for the recurring job pod to start)
```

#### 6. Complete the test case

Following the above steps, convert each step in the [manual test case](https://longhorn.github.io/longhorn-tests/manual/release-specific/v1.1.0/recurring-backup-job-interruptions/) into clear, human-readable Robot Framework test case.

## Run a test

From the `longhorn-tests/e2e` folder, execute the test with:

```
/run.sh -t "Recurring backup job interruptions when Allow Recurring Job While Volume Is Detached is disabled"
```
 
Robot Framework will generate a standard test report.

<img src="/img/blogs/20260119-writing-end-to-end-case-for-Longhorn/robot-test-report.png" alt="Descriptive alt text">