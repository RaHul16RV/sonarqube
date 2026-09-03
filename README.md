# 🔍 SonarQube Issue Export Tool

A Bash-based utility to export issues from **SonarQube** into **JSON** and **CSV** reports.

This tool is designed to work with **multiple SonarQube environments** such as DEV, QA, UAT, and PROD without modifying the script.

When the script is executed, it interactively asks for:

- SonarQube URL
- SonarQube Authentication Token
- Component / Project Key
- Issue Severity
- Issue Status

The script then connects to SonarQube, retrieves all matching issues using the SonarQube REST API, handles pagination automatically, and generates timestamped JSON and CSV reports.

---

# 📘 Project Overview

This project demonstrates how to:

- Connect to SonarQube using REST APIs
- Authenticate using a SonarQube token
- Search SonarQube issues
- Filter issues by severity
- Filter issues by status
- Handle SonarQube API pagination
- Export issues to JSON
- Export issues to CSV
- Generate timestamped reports
- Store reports in a separate directory
- Prevent generated reports from being committed to Git
- Use the same script across multiple environments

---

# 🎯 Why This Tool?

Normally, SonarQube issues can be viewed from the SonarQube web interface.

However, when you need to:

- Download issues
- Share issue reports
- Analyze issues in Excel
- Archive issue reports
- Perform automation
- Integrate issue exports into CI/CD
- Compare issues between environments

manually exporting issues can become time-consuming.

This script automates the entire process.

---

# 🛠️ Technologies Used

| Technology | Purpose |
|------------|---------|
| Bash | Script automation |
| cURL | API communication |
| jq | JSON parsing and transformation |
| SonarQube | Code quality and security analysis |
| Git | Version control |
| GitHub | Source code repository |

---

# 📂 Project Structure

The recommended project structure is:

```text
sonarqube-issue-export/
│
├── sonarqube-export.sh
├── README.md
│
└── sonarqube-issue/
    └── .gitignore
