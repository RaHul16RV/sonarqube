SonarQube Issue Export Tool

A Bash script to export SonarQube issues into JSON and CSV files.

The script allows you to provide the SonarQube URL, authentication token, project/component key, issue severity, and issue status at runtime.

Features
Connects to any SonarQube environment.
No environment-specific URL is hard-coded.
Prompts for the SonarQube authentication token securely.
Supports filtering by:
Severity
Status
Component/Project Key
Automatically handles pagination.
Fetches up to 500 issues per API request.
Exports results to:
JSON
CSV
Generates timestamped output files.
Automatically cleans up temporary files.
Creates a .gitignore to prevent exported issue files from being committed.
Requirements

The following tools are required:

Bash
curl
jq
Check dependencies
bash --version
curl --version
jq --version

Install dependencies on Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y curl jq

Project Structure

Example repository structure:

.
├── sonarqube-export.sh
├── README.md
└── sonarqube-issue/
    └── .gitignore


The sonarqube-issue directory and export files are created automatically when the script runs.

Installation

Clone the repository:

git clone <YOUR-GITHUB-REPOSITORY-URL>


Move into the repository:

cd <YOUR-REPOSITORY-NAME>


Make the script executable:

chmod +x sonarqube-export.sh

Usage

Run the script:

./sonarqube-export.sh


The script will ask for the following information.

1. SonarQube URL

Example:

SonarQube URL: https://sonarqube.example.com


You can provide the URL for any environment such as:

DEV
QA
UAT
PROD


No environment-specific configuration is required in the script.

2. SonarQube Token

The script securely prompts for the token:

SonarQube Token:


The token will not be displayed while typing.

Never commit a SonarQube token to GitHub.

3. Component Key

Enter the SonarQube project/component key.

Example:

Component Key: SC-ADMIN-BACKEND

4. Severity

The script provides the following options:

Severity options:
  1) BLOCKER
  2) CRITICAL
  3) MAJOR
  4) MINOR
  5) INFO
  6) ALL


The default is:

CRITICAL


Press Enter to use the default.

For example:

Severity [CRITICAL]: 2


will export only CRITICAL issues.

To export all severities:

Severity [CRITICAL]: 6

5. Status

The script provides:

Status options:
  1) OPEN
  2) CONFIRMED
  3) REOPENED
  4) RESOLVED
  5) CLOSED
  6) ALL


The default is:

OPEN


Press Enter to use the default.

For example:

Status [OPEN]: 1


will export only open issues.

Example

Run:

./sonarqube-export.sh


Example interaction:

==============================================
       SonarQube Issue Export Tool
==============================================

SonarQube URL: https://sonarqube.example.com
SonarQube Token:
Component Key: SC-ADMIN-BACKEND

Severity options:
  1) BLOCKER
  2) CRITICAL
  3) MAJOR
  4) MINOR
  5) INFO
  6) ALL

Severity [CRITICAL]: 2

Status options:
  1) OPEN
  2) CONFIRMED
  3) REOPENED
  4) RESOLVED
  5) CLOSED
  6) ALL

Status [OPEN]: 1


The script will then connect to SonarQube and start fetching issues.

Example output:

Checking SonarQube connection...
SonarQube connection successful.

Fetching issues...
  Page 1: 500 issues (Total: 723)
  Page 2: 223 issues (Total: 723)

Creating JSON export...
Creating CSV export...

==============================================
             Export Completed
==============================================

Issues exported : 723

Output

The script creates an output directory:

sonarqube-issue/


Example:

sonarqube-issue/
├── .gitignore
├── sonar-issues-20260903_135500.json
└── sonar-issues-20260903_135500.csv

JSON Output

The JSON file contains:

{
  "total": 723,
  "issues": [
    {
      "key": "ABC123",
      "component": "SC-ADMIN-BACKEND:src/main/java/example/Test.java",
      "line": 42,
      "rule": "java:S1234",
      "severity": "CRITICAL",
      "type": "VULNERABILITY",
      "status": "OPEN",
      "message": "Example issue",
      "effort": "30min",
      "tags": [
        "security"
      ]
    }
  ]
}

CSV Output

The CSV contains the following columns:

Issue Key
Component
File
Line
Rule
Severity
Type
Status
Message
Effort
Tags


This makes the exported issues easy to open in Excel or other spreadsheet applications.

Pagination

The script retrieves issues in batches of 500.

For example, if SonarQube has 1,250 matching issues:

Page 1: 500 issues
Page 2: 500 issues
Page 3: 250 issues


The script automatically combines all pages into a single JSON and CSV export.

API Endpoints Used

The script uses the following SonarQube REST API endpoints:

Check SonarQube Status
/api/system/status


Used to verify that the SonarQube server is reachable and the authentication is working.

Search Issues
/api/issues/search


Used to retrieve SonarQube issues based on the selected filters.

Security
Do not commit SonarQube tokens

Never add tokens directly to:

sonarqube-export.sh
README.md
.env
configuration files


Do not run commands such as:

git add .
git commit -m "add sonar token"


if the token is stored in a file.

The script intentionally asks for the token interactively:

SonarQube Token:


The token is hidden while entering it.

If a token is accidentally committed

Immediately revoke/rotate the token in SonarQube.

Removing the token from the latest commit is not sufficient if it has already been pushed to GitHub, because it may remain in Git history.

Git Ignore

The script automatically creates:

sonarqube-issue/.gitignore


with:

*
!.gitignore


This prevents generated JSON and CSV reports from being committed.

Troubleshooting
curl is not installed

Error:

ERROR: curl is required.


Install:

sudo apt-get install -y curl

jq is not installed

Error:

ERROR: jq is required.


Install:

sudo apt-get install -y jq

Cannot connect to SonarQube

Error:

ERROR: Unable to connect to SonarQube.


Check:

SonarQube URL
Network connectivity
Firewall rules
Proxy configuration
SonarQube availability
Authentication token

You can test connectivity manually:

curl -u "YOUR_TOKEN:" \
  "https://sonarqube.example.com/api/system/status"


Do not paste your real token into the README or Git repository.

HTTP 401

Example:

ERROR: SonarQube API returned HTTP 401


This generally indicates an authentication problem.

Check that:

The token is correct.
The token has not expired/revoked.
The token has sufficient permissions.
The token belongs to the correct SonarQube server.
HTTP 403

Example:

ERROR: SonarQube API returned HTTP 403


The authenticated user/token may not have permission to access the project or issue information.

Verify the user's permissions for the specified SonarQube project.

Invalid component/project key

Make sure the component key exactly matches the project key configured in SonarQube.

Example:

SC-ADMIN-BACKEND

GitHub Setup

After creating the files:

.
├── sonarqube-export.sh
└── README.md


Check the files:

ls -la


Make sure the script is executable:

chmod +x sonarqube-export.sh


Check Git status:

git status


Add the files:

git add sonarqube-export.sh README.md


Commit:

git commit -m "Add SonarQube issue export tool"


Push:

git push origin main


Replace main with your repository's branch if necessary.

Quick Start

For experienced users:

git clone <YOUR-GITHUB-REPOSITORY-URL>
cd <YOUR-REPOSITORY-NAME>
chmod +x sonarqube-export.sh
./sonarqube-export.sh


Then provide:

SonarQube URL
SonarQube Token
Component Key
Severity
Status


The generated reports will be available under:

sonarqube-issue/

License

Add your organization's applicable license or usage terms here.

:::

## How to put this on GitHub

If you already have the repository, on your machine:

```bash
cd your-repository


Create the README:

nano README.md


Paste the README content above, then save it.

Then:

git add README.md
git commit -m "Add README for SonarQube issue export tool"
git push origin main


If you already have a README.md, don't overwrite it blindly. Add the relevant sections to your existing README instead.

Your GitHub repository can look like this
sonarqube-issue-export/
│
├── sonarqube-export.sh
├── README.md
│
└── sonarqube-issue/
    └── .gitignore


And importantly, there should be no SonarQube token anywhere in the repository.
