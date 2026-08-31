# KEM-012-PROJECT-FILE-DOCUMENT-GOVERNANCE.md

# KemetRise — Legacy Nexus

## MR.ESS Project Operating System

### PROJECT FILE & DOCUMENT GOVERNANCE

**Document ID:** KEM-012
**System ID:** MR-ESS-POS
**Parent System:** KemetRise — Legacy Nexus
**Parent Layer:** Control Tower
**Organization:** KemetRise — Legacy Nexus
**Owner:** MR.ESS
**Version:** 1.0.0
**Status:** FOUNDATION
**Classification:** INTERNAL — CRITICAL
**Date:** 2026-08-31

---

# 1. PURPOSE

KEM-012 defines the organizational standard for all project files, documents, assets, specifications, contracts, designs, reports, prompts, manuals, and operational documentation across KemetRise.

The purpose is to eliminate:

```text
Lost Files
Duplicate Files
Wrong Versions
Mixed Projects
Unknown Ownership
Unknown Status
Unknown Location
```

---

# 2. CORE PRINCIPLE

Every file must answer five questions:

```text
1. WHAT IS IT?
2. WHICH PROJECT DOES IT BELONG TO?
3. WHO OWNS IT?
4. WHAT IS ITS CURRENT VERSION?
5. WHERE IS THE AUTHORITATIVE COPY?
```

If these questions cannot be answered, the file is considered:

```text
UNCONTROLLED ARTIFACT
```

---

# 3. FILE GOVERNANCE MODEL

```text
                         CONTROL TOWER
                              │
                       FILE REGISTRY
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
      PROJECT 001         PROJECT 002         PROJECT 003
          │                   │                   │
          ▼                   ▼                   ▼
       DOCUMENTS           DOCUMENTS           DOCUMENTS
       ASSETS              ASSETS              ASSETS
       SPECS               SPECS               SPECS
       CONTRACTS           CONTRACTS           CONTRACTS
```

---

# 4. FILE IDENTITY

Important controlled files receive unique identifiers.

Examples:

```text
FILE-000001
DOC-000001
SPEC-000001
CON-000001
DES-000001
REP-000001
```

---

# 5. PROJECT ID

Every project must have a unique Project ID.

Example:

```text
PRJ-0001
PRJ-0002
PRJ-0003
```

---

# 6. FILE → PROJECT RELATIONSHIP

Every controlled file must be associated with:

```text
Project ID
```

or explicitly classified as:

```text
GLOBAL
SHARED
CORPORATE
CONTROL-TOWER
```

---

# 7. GLOBAL FILES

Corporate-level files may belong to:

```text
KemetRise Global
```

Examples:

```text
Brand Guidelines
Corporate Policies
Legal Templates
Company Standards
```

---

# 8. SHARED FILES

A document used by multiple projects must be classified as:

```text
SHARED
```

and registered accordingly.

---

# 9. NO ORPHAN FILES

Files should not exist in the organizational system without a known ownership context.

---

# 10. FILE CATEGORIES

Primary categories:

```text
01 — GOVERNANCE
02 — PROJECT MANAGEMENT
03 — BUSINESS
04 — PRODUCT
05 — TECHNICAL
06 — DATABASE
07 — INFRASTRUCTURE
08 — AUTOMATION
09 — AI
10 — DESIGN
11 — MARKETING
12 — SALES
13 — LEGAL
14 — FINANCE
15 — OPERATIONS
16 — REPORTS
17 — TRAINING
18 — ARCHIVE
```

---

# 11. GOVERNANCE FILES

Examples:

```text
Policies
Standards
Protocols
SOPs
Governance Documents
Architecture Rules
```

---

# 12. PROJECT MANAGEMENT FILES

Examples:

```text
Roadmaps
Tasks
Milestones
Plans
Meeting Notes
Decision Logs
Status Reports
```

---

# 13. BUSINESS FILES

Examples:

```text
Business Plan
Revenue Model
Pricing
Market Analysis
Business Strategy
```

---

# 14. PRODUCT FILES

Examples:

```text
Product Requirements
Features
Specifications
User Stories
Product Roadmap
```

---

# 15. TECHNICAL FILES

Examples:

```text
Architecture
API Documentation
Technical Specifications
Engineering Notes
ADRs
```

---

# 16. DATABASE FILES

Examples:

```text
Schema
Migrations
Database Documentation
ERD
Policies
Seed Data
```

---

# 17. INFRASTRUCTURE FILES

Examples:

```text
Server Specifications
Docker
Terraform
Ansible
Networking
Deployment
Monitoring
Backup
Recovery
```

---

# 18. AUTOMATION FILES

Examples:

```text
n8n Workflows
Automation Specifications
Workflow Documentation
Triggers
Actions
Credentials References
```

---

# 19. AI FILES

Examples:

```text
AI Agents
System Prompts
Prompt Templates
Model Configurations
Agent Specifications
AI Policies
Evaluation Reports
```

---

# 20. DESIGN FILES

Examples:

```text
UI
UX
Wireframes
Mockups
Brand Assets
Design Systems
```

---

# 21. MARKETING FILES

Examples:

```text
Campaigns
Content
Ads
Scripts
Creative Briefs
Marketing Plans
```

---

# 22. SALES FILES

Examples:

```text
Sales Strategy
Offers
Proposals
Pricing
Customer Materials
Sales Scripts
```

---

# 23. LEGAL FILES

Examples:

```text
Contracts
Annexes
Terms
Policies
Agreements
Licenses
```

---

# 24. FINANCE FILES

Examples:

```text
Budgets
Financial Models
Invoices
Forecasts
Cost Analysis
```

---

# 25. OPERATIONS FILES

Examples:

```text
SOPs
Runbooks
Operational Manuals
Checklists
Incident Procedures
```

---

# 26. REPORT FILES

Examples:

```text
Weekly Reports
Monthly Reports
Analytics
Performance Reports
Executive Reports
```

---

# 27. TRAINING FILES

Examples:

```text
Training Manuals
Courses
Tutorials
Employee Guides
Knowledge Base
```

---

# 28. ARCHIVE

Obsolete or historical files must be moved to:

```text
ARCHIVE
```

rather than casually deleted.

---

# 29. FILE LIFECYCLE

Every controlled document follows:

```text
DRAFT
 ↓
REVIEW
 ↓
APPROVED
 ↓
ACTIVE
 ↓
SUPERSEDED
 ↓
ARCHIVED
```

---

# 30. FILE STATUS

Allowed states:

```text
DRAFT
IN REVIEW
APPROVED
ACTIVE
BLOCKED
SUPERSEDED
ARCHIVED
RETIRED
```

---

# 31. DRAFT

Draft files are not authoritative.

---

# 32. IN REVIEW

The document is awaiting validation or approval.

---

# 33. APPROVED

The document has passed its required approval process.

---

# 34. ACTIVE

The approved document is currently operational.

---

# 35. SUPERSEDED

A newer authoritative version exists.

---

# 36. ARCHIVED

The file is retained for historical or legal purposes.

---

# 37. RETIRED

The file is no longer required operationally.

---

# 38. VERSION CONTROL

Controlled documents must use explicit versions.

Recommended:

```text
v0.1
v0.2
v1.0
v1.1
v2.0
```

---

# 39. VERSION RULE

```text
0.x
Development

1.0
First Approved Version

1.x
Minor Changes

2.0
Major Structural Change
```

---

# 40. DOCUMENT IDENTITY

Recommended metadata:

```text
Document ID
Project ID
Document Type
Title
Version
Status
Owner
Author
Approver
Created Date
Updated Date
Supersedes
Superseded By
```

---

# 41. AUTHORITATIVE COPY

Every important document must have exactly one:

```text
SOURCE OF TRUTH
```

---

# 42. DUPLICATES

Copies may exist for convenience, but only one should be designated authoritative.

---

# 43. DUPLICATE WARNING

If multiple files have identical or conflicting content, the Control Tower should flag them for review.

---

# 44. FILE NAMING STANDARD

Recommended:

```text
<KEM-ID>-<PROJECT-ID>-<TYPE>-<NAME>-v<VERSION>.<EXT>
```

Example:

```text
KEM-012-PRJ-0001-SPEC-PRODUCT-REQUIREMENTS-v1.0.md
```

---

# 45. SHORT FILE NAMES

Where appropriate:

```text
KEM-012-PRJ-0001-ARCH-v1.0.md
```

---

# 46. NO CHAOTIC NAMES

Avoid:

```text
final.docx
final2.docx
newfinal.docx
newfinal2.docx
latest.docx
latest-final.docx
really-final.docx
```

---

# 47. APPROVED VERSION

Instead use:

```text
KEM-012-PRJ-0001-CONTRACT-v2.1.docx
```

---

# 48. FILE EXTENSIONS

Use extensions according to purpose.

Examples:

```text
.md
.docx
.pdf
.xlsx
.pptx
.csv
.json
.yaml
.png
.jpg
.svg
```

---

# 49. MARKDOWN

Use Markdown for:

```text
Specifications
Technical Documentation
Architecture
Protocols
AI Specifications
Developer Documentation
```

---

# 50. WORD

Use Word for:

```text
Contracts
Formal Reports
Business Documents
Client Documents
Official Documents
```

---

# 51. PDF

PDF is preferred for:

```text
Final Distribution
Approved Contracts
Final Reports
Investor Materials
Official Deliverables
```

---

# 52. SPREADSHEETS

Use spreadsheets for:

```text
Financial Models
Inventories
Pricing
Data Tables
Operational Registers
```

---

# 53. PRESENTATIONS

Use presentations for:

```text
Investor Decks
Sales Presentations
Executive Presentations
Training
```

---

# 54. SOURCE FILE VS OUTPUT FILE

Distinguish:

```text
SOURCE
```

from:

```text
FINAL OUTPUT
```

---

# 55. SOURCE OF TRUTH

Example:

```text
SPECIFICATION.md
```

may be the source.

Generated:

```text
SPECIFICATION.pdf
SPECIFICATION.docx
```

are outputs.

---

# 56. GENERATED FILES

Generated outputs should not replace the authoritative source unless explicitly approved.

---

# 57. DOCUMENT GENERATION

Recommended:

```text
SOURCE
 ↓
GENERATION
 ↓
VALIDATION
 ↓
OUTPUT
```

---

# 58. DOCUMENT APPROVAL

Approval metadata should identify:

```text
Approver
Date
Version
Decision
```

---

# 59. APPROVAL STATES

```text
PENDING
APPROVED
REJECTED
CONDITIONAL
```

---

# 60. DOCUMENT OWNER

Every critical document must have an owner.

---

# 61. DOCUMENT REVIEW

Important documents should have a review cycle.

Example:

```text
Quarterly
Semiannual
Annual
Event-Based
```

---

# 62. REVIEW DATE

Metadata:

```text
Next Review Date
```

---

# 63. EXPIRED DOCUMENTS

Documents past their required review date may be flagged:

```text
REVIEW REQUIRED
```

---

# 64. DOCUMENT DEPENDENCIES

Documents may depend on:

```text
Other Documents
Systems
Projects
Contracts
Policies
Specifications
```

---

# 65. DOCUMENT RELATIONSHIPS

Example:

```text
BUSINESS PLAN
     │
     ├── FINANCIAL MODEL
     ├── PRODUCT SPEC
     └── ROADMAP
```

---

# 66. DOCUMENT GRAPH

Control Tower should eventually visualize:

```text
DOCUMENT
│
├── DEPENDS ON
├── REFERENCES
├── SUPERSEDES
├── GENERATED FROM
└── USED BY
```

---

# 67. CONTRACT MANAGEMENT

Contracts receive:

```text
CON-XXXX
```

---

# 68. CONTRACT METADATA

```text
Contract ID
Project
Parties
Type
Version
Effective Date
Expiration Date
Status
Owner
```

---

# 69. CONTRACT VERSIONING

Never overwrite an executed contract.

---

# 70. EXECUTED DOCUMENT

Signed documents must be preserved as immutable records.

---

# 71. LEGAL ARCHIVE

Executed legal documents belong in controlled storage.

---

# 72. EXPIRATION ALERTS

Contracts with expiration dates should generate alerts.

---

# 73. DESIGN ASSETS

Design files receive:

```text
DES-XXXX
```

---

# 74. DESIGN ASSET TYPES

```text
Logo
Icon
UI
Mockup
Banner
Video
Image
Illustration
3D
```

---

# 75. BRAND ASSETS

Brand assets should include:

```text
Logo
Colors
Typography
Icons
Photography
Voice
Visual Guidelines
```

---

# 76. ASSET MASTER

Each important asset should have a master/source version.

---

# 77. ASSET DERIVATIVES

Examples:

```text
MASTER
 ↓
WEB
SOCIAL
PRINT
VIDEO
```

---

# 78. MEDIA FILE NAMING

Recommended:

```text
<PROJECT>-<ASSET-TYPE>-<DESCRIPTION>-v<VERSION>
```

---

# 79. IMAGE VERSIONING

Do not overwrite approved visual assets without version control.

---

# 80. VIDEO VERSIONING

Example:

```text
MISS-EVE-AD-001-v1.0.mp4
MISS-EVE-AD-001-v1.1.mp4
MISS-EVE-AD-001-v2.0.mp4
```

---

# 81. PROMPT GOVERNANCE

AI prompts are controlled project assets.

---

# 82. PROMPT ID

Example:

```text
PROMPT-0001
```

---

# 83. PROMPT METADATA

```text
Prompt ID
Project
Agent
Model
Purpose
Version
Status
Owner
```

---

# 84. AI PROMPT SOURCE

Prompts should have a canonical source.

---

# 85. PROMPT TESTING

Important prompts should be evaluated before becoming production prompts.

---

# 86. AI OUTPUTS

AI-generated files should be classified as:

```text
DRAFT
REVIEWED
APPROVED
REJECTED
```

---

# 87. AI ARTIFACT TRACEABILITY

Where practical, record:

```text
Model
Prompt Version
Input Reference
Output
Date
Operator
```

---

# 88. SPECIFICATION FILES

Specifications should receive:

```text
SPEC-XXXX
```

---

# 89. SPECIFICATION TYPES

```text
Business Specification
Product Specification
Technical Specification
API Specification
Database Specification
AI Specification
Infrastructure Specification
```

---

# 90. KEM FILES

KEM documents remain part of the KemetRise governance system.

Example:

```text
KEM-000
KEM-001
KEM-010
KEM-011
KEM-012
```

---

# 91. KEM OWNERSHIP

KEM governance documents belong to:

```text
KemetRise — Legacy Nexus
```

unless explicitly designated project-specific.

---

# 92. PROJECT DOCUMENTATION

Each project should contain:

```text
Project Overview
Business Plan
Product Specification
Architecture
Database
Infrastructure
Automation
AI
Operations
Legal
Finance
Marketing
```

as applicable.

---

# 93. PROJECT MASTER INDEX

Every substantial project should have:

```text
PROJECT-INDEX.md
```

---

# 94. PROJECT INDEX PURPOSE

It answers:

```text
Where is everything?
```

---

# 95. PROJECT INDEX EXAMPLE

```text
PRJ-0001
│
├── 01-GOVERNANCE
├── 02-BUSINESS
├── 03-PRODUCT
├── 04-TECHNICAL
├── 05-DATABASE
├── 06-INFRASTRUCTURE
├── 07-AUTOMATION
├── 08-AI
├── 09-DESIGN
├── 10-MARKETING
├── 11-SALES
├── 12-LEGAL
├── 13-FINANCE
├── 14-OPERATIONS
├── 15-REPORTS
└── 99-ARCHIVE
```

---

# 96. PROJECT ROOT

Recommended:

```text
PRJ-0001/
```

---

# 97. DIRECTORY STANDARD

```text
PRJ-0001/
│
├── 01-GOVERNANCE/
├── 02-BUSINESS/
├── 03-PRODUCT/
├── 04-TECHNICAL/
├── 05-DATABASE/
├── 06-INFRASTRUCTURE/
├── 07-AUTOMATION/
├── 08-AI/
├── 09-DESIGN/
├── 10-MARKETING/
├── 11-SALES/
├── 12-LEGAL/
├── 13-FINANCE/
├── 14-OPERATIONS/
├── 15-REPORTS/
├── 16-TRAINING/
└── 99-ARCHIVE/
```

---

# 98. FILE LOCATION RULE

A file must be stored according to:

```text
PROJECT
 ↓
CATEGORY
 ↓
SUBCATEGORY
 ↓
DOCUMENT
```

---

# 99. NO RANDOM STORAGE

Do not keep project files scattered across:

```text
Desktop
Downloads
Random Folders
Personal Drives
Uncontrolled Cloud Storage
```

as authoritative copies.

---

# 100. WORKING FILES

Temporary working files may exist locally.

They are not authoritative until registered.

---

# 101. INBOX

Each project may have:

```text
00-INBOX/
```

for newly received files.

---

# 102. INBOX RULE

Inbox files must eventually be:

```text
CLASSIFIED
RENAMED
REGISTERED
MOVED
ARCHIVED
```

---

# 103. FILE TRIAGE

Workflow:

```text
INBOX
 ↓
IDENTIFY
 ↓
CLASSIFY
 ↓
PROJECT ASSIGNMENT
 ↓
RENAME
 ↓
VERSION
 ↓
STORE
 ↓
REGISTER
```

---

# 104. UNKNOWN FILES

Unknown files should be placed temporarily in:

```text
00-INBOX/UNKNOWN/
```

until classified.

---

# 105. FILE REGISTRY

The Control Tower should maintain:

```text
File ID
Project ID
Path
Category
Type
Version
Status
Owner
Created
Updated
Source
```

---

# 106. FILE SEARCH

The Control Tower should eventually support:

```text
Search by Project
Search by File ID
Search by Type
Search by Owner
Search by Version
Search by Status
Search by Keyword
```

---

# 107. DOCUMENT TAGGING

Useful tags:

```text
PROJECT
LEGAL
TECHNICAL
AI
FINANCE
MARKETING
APPROVED
DRAFT
CONFIDENTIAL
ARCHIVE
```

---

# 108. CLASSIFICATION

Documents may be classified:

```text
PUBLIC
INTERNAL
CONFIDENTIAL
RESTRICTED
CRITICAL
```

---

# 109. ACCESS CONTROL

Sensitive documents must have appropriate access restrictions.

---

# 110. DOCUMENT SECURITY

Never expose:

```text
Passwords
Private Keys
Authentication Tokens
Secret Credentials
```

inside ordinary documentation.

---

# 111. SECRET REFERENCES

Documentation may contain references such as:

```text
SECRET_REF:
KEMETRISE_PROD_DB_PASSWORD
```

without revealing the secret value.

---

# 112. DOCUMENT BACKUP

Critical documentation must be backed up.

---

# 113. DOCUMENT RECOVERY

A project should remain recoverable even if its primary file store fails.

---

# 114. ARCHIVE POLICY

Archive rather than delete important historical artifacts.

---

# 115. DELETION

Permanent deletion of critical documents requires authorization.

---

# 116. RETENTION

Retention periods should be determined by:

```text
Business Need
Legal Requirement
Contractual Requirement
Operational Need
Security
```

---

# 117. DOCUMENT AUDIT

The Control Tower should detect:

```text
Duplicate Files
Missing Metadata
Expired Documents
Conflicting Versions
Orphan Files
Unclassified Files
```

---

# 118. DOCUMENT HEALTH SCORE

Possible dimensions:

```text
Classification
Ownership
Versioning
Status
Backup
Security
Review Status
```

---

# 119. PROJECT DOCUMENT HEALTH

Example:

```text
PROJECT:
PRJ-0007

Documents:
248

Controlled:
241

Unclassified:
5

Duplicates:
2

Expired:
0

Overall:
97%
```

---

# 120. DOCUMENT CHANGE LOG

Important documents should record:

```text
Version
Change
Author
Date
Reason
```

---

# 121. DOCUMENT DECISION LOG

Important decisions should be captured separately.

Example:

```text
DEC-0001
Decision:
Use Supabase for Project Database

Reason:
...

Date:
...

Owner:
...
```

---

# 122. MEETING NOTES

Meeting records should include:

```text
Date
Participants
Purpose
Decisions
Actions
Owners
Deadlines
```

---

# 123. ACTION REGISTER

Important actions should be linked to:

```text
Task ID
Project ID
Document
Owner
Deadline
Status
```

---

# 124. DOCUMENT → TASK

A document may generate tasks.

```text
DOCUMENT
 ↓
ACTION
 ↓
TASK
```

---

# 125. DOCUMENT → PROJECT

Documents may create or modify project requirements.

---

# 126. DOCUMENT → CODE

Specifications may map to:

```text
Repository
Feature
Issue
Release
```

---

# 127. DOCUMENT → INFRASTRUCTURE

Infrastructure specifications may map to:

```text
Server
Container
Network
Deployment
```

---

# 128. DOCUMENT → DATABASE

Database specifications may map to:

```text
Database
Table
Migration
Policy
```

---

# 129. DOCUMENT → AI AGENT

AI specifications may map to:

```text
Agent
Prompt
Model
Workflow
Tools
Permissions
```

---

# 130. COMPLETE PROJECT TRACEABILITY

The Control Tower should eventually support:

```text
DOCUMENT
 ↓
REQUIREMENT
 ↓
CODE
 ↓
BUILD
 ↓
RELEASE
 ↓
DEPLOYMENT
 ↓
SERVER
 ↓
DATABASE
 ↓
USER
```

---

# 131. DOCUMENT GENERATION PIPELINE

```text
RAW INFORMATION
 ↓
DRAFT
 ↓
AI / HUMAN PROCESSING
 ↓
REVIEW
 ↓
APPROVAL
 ↓
VERSION
 ↓
PUBLISH
 ↓
ARCHIVE PREVIOUS VERSION
```

---

# 132. AI DOCUMENTATION AGENT

Future AI Employee:

```text
Documentation AI
```

Responsibilities:

```text
Organize Files
Detect Duplicates
Generate Indexes
Summarize Documents
Detect Missing Documentation
Track Versions
```

---

# 133. AI FILE CLASSIFICATION

The AI may classify files by:

```text
Project
Category
Document Type
Importance
Status
```

subject to human governance.

---

# 134. AI FILE RENAMING

AI may recommend standardized names.

Automatic renaming should be controlled to avoid destructive changes.

---

# 135. AI DUPLICATE DETECTION

The system should identify:

```text
Exact Duplicates
Near Duplicates
Conflicting Versions
```

---

# 136. AI DOCUMENT MAP

Future Control Tower capability:

```text
PROJECT
│
├── 248 DOCUMENTS
├── 61 ASSETS
├── 32 SPECIFICATIONS
├── 14 CONTRACTS
├── 19 REPORTS
└── 7 ARCHIVED VERSIONS
```

---

# 137. DOCUMENT COMMAND CENTER

Example:

```text
KEMETRISE DOCUMENT COMMAND CENTER

Projects: 18

Documents: 4,821
Controlled: 4,702
Draft: 83
Review: 21
Archived: 15

Unclassified: 9
Duplicates: 4

Critical Documents:
97%
Healthy
```

---

# 138. NEW PROJECT DOCUMENT FACTORY

When a new project is created:

```text
PROJECT CREATED
      ↓
CREATE PROJECT ID
      ↓
CREATE PROJECT FOLDER
      ↓
CREATE PROJECT INDEX
      ↓
CREATE STANDARD CATEGORIES
      ↓
REGISTER IN CONTROL TOWER
```

---

# 139. AUTOMATIC PROJECT FOLDER

Example:

```text
PRJ-0024/
```

is automatically initialized with:

```text
00-INBOX
01-GOVERNANCE
02-BUSINESS
03-PRODUCT
04-TECHNICAL
05-DATABASE
06-INFRASTRUCTURE
07-AUTOMATION
08-AI
09-DESIGN
10-MARKETING
11-SALES
12-LEGAL
13-FINANCE
14-OPERATIONS
15-REPORTS
16-TRAINING
99-ARCHIVE
```

---

# 140. PROJECT MASTER INDEX

The project index should link to every major artifact.

---

# 141. FILE REGISTRY ENTRY

Example:

```text
FILE-ID:
FILE-002481

PROJECT:
PRJ-0024

TYPE:
Technical Specification

NAME:
Payment Architecture

VERSION:
v1.3

STATUS:
ACTIVE

OWNER:
Technical Lead

LOCATION:
04-TECHNICAL/

SOURCE OF TRUTH:
YES
```

---

# 142. DOCUMENT STATUS DASHBOARD

Example:

```text
DRAFT        83
IN REVIEW    21
APPROVED     14
ACTIVE       391
SUPERSEDED   62
ARCHIVED     4,250
```

---

# 143. DOCUMENT GOVERNANCE RULE

A document should never be considered authoritative simply because:

```text
It has "final" in its filename.
```

Authority comes from:

```text
Registry
Version
Status
Approval
Ownership
```

---

# 144. PROJECT ISOLATION

Project documents must not be mixed with another project's controlled documents.

---

# 145. SHARED DOCUMENTS

Shared documents must explicitly identify every consuming project where relevant.

---

# 146. CONTROL TOWER VISIBILITY

The Control Tower must be able to answer:

```text
Where are this project's files?

What is the latest approved specification?

Which contract is active?

Which version is authoritative?

Which documents are obsolete?

Which files are duplicates?

Which documents require review?

Who owns this document?
```

---

# 147. MASTER PROJECT MAP

Eventually:

```text
                         CONTROL TOWER
                               │
                               ▼
                       PROJECT REGISTRY
                               │
       ┌───────────────────────┼───────────────────────┐
       ▼                       ▼                       ▼
    PROJECT A               PROJECT B               PROJECT C
       │                       │                       │
   DOCUMENTS                DOCUMENTS                DOCUMENTS
       │                       │                       │
     SPECS                   SPECS                   SPECS
     CONTRACTS               CONTRACTS               CONTRACTS
     ASSETS                  ASSETS                  ASSETS
     REPORTS                 REPORTS                 REPORTS
       │                       │                       │
       └───────────────────────┼───────────────────────┘
                               ▼
                         FILE REGISTRY
```

---

# 148. DEFINITION OF DONE

KEM-012 is complete when KemetRise can:

```text
Create Project File Structure
Assign File IDs
Assign Project IDs
Classify Files
Track Versions
Track Status
Track Ownership
Track Approvals
Track Source of Truth
Detect Duplicates
Track Contracts
Track Assets
Track Prompts
Track Specifications
Track Reports
Archive Historical Versions
Search Files
Audit File Health
Map File Relationships
```

---

# 149. FINAL PRINCIPLE

KemetRise must never reach a point where MR.ESS asks:

> "فين آخر نسخة من الملف؟"

or:

> "ده الملف المعتمد ولا نسخة قديمة؟"

or:

> "الملف ده بتاع أنهي مشروع؟"

or:

> "مين صاحب الملف ده؟"

or:

> "إيه الملف اللي يعتبر Source of Truth؟"

The Control Tower must answer immediately.

Therefore:

# EVERY CONTROLLED FILE HAS AN ID.

# EVERY FILE BELONGS TO A PROJECT OR EXPLICIT GLOBAL CATEGORY.

# EVERY IMPORTANT FILE HAS AN OWNER.

# EVERY IMPORTANT FILE HAS A VERSION.

# EVERY IMPORTANT FILE HAS A STATUS.

# EVERY PROJECT HAS A MASTER INDEX.

# EVERY IMPORTANT DOCUMENT HAS ONE SOURCE OF TRUTH.

# NOTHING IMPORTANT IS LOST IN RANDOM FOLDERS.

---

# END OF KEM-012

**KemetRise — Legacy Nexus**

**MR.ESS Project Operating System**

**PROJECT FILE & DOCUMENT GOVERNANCE**

**Version:** 1.0.0

**STATUS:** FOUNDATION
