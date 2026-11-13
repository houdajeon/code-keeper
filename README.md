# Code-Keeper: Tasks for Aymen and Houda

## Overview

Build a complete CI/CD pipeline for the `crud-master` microservices (on top of
our `cloud-design` infrastructure) and deploy it to a **staging** and a
**production** environment, with security, automation and reliability at every
step.

Applications:

- `inventory-app`: connected to the inventory database
- `billing-app`: connected to the billing database and consuming the RabbitMQ
  queue
- `api-gateway-app`: forwards the requests to the other services

Repositories to create in our GitLab (each application has its own
repository):

| Repository | Owner | Pipeline |
|------------|-------|----------|
| `ansible-gitlab` | Aymen | Ansible playbook for GitLab and the Runners |
| `infrastructure` | Aymen | Init → Validate → Plan → Apply Staging → Approval → Apply Production |
| `inventory-app` | Houda | CI (Build → Test → Scan → Containerize) + CD (Staging → Approval → Production) |
| `billing-app` | Houda | CI + CD |
| `api-gateway-app` | Houda | CI + CD |

---

## Aymen's tasks

### Task 1: Deploy GitLab with Ansible

- [ ] Write an Ansible playbook that installs GitLab and all its dependencies
- [ ] Configure user authentication: create the users (Aymen, Houda,
      reviewer) and disable public sign-up
- [ ] Configure the project settings: group, the 5 projects, merge requests
      and code reviews
- [ ] Configure the CI/CD settings: protected variables, protected branches,
      environments
- [ ] Deploy GitLab on the cloud (AWS EC2) with the playbook and make it
      reachable by both team members
- [ ] Be able to run the deployment live during the audit

### Task 2: GitLab Runners

- [ ] Add the Runner installation and registration to the Ansible playbook
- [ ] Use the Docker executor, with tags so that each job runs on the right
      runner
- [ ] Use a protected runner for the deploy jobs, so that it only runs on
      protected branches
- [ ] Check that every pipeline runs on our own Runners

### Task 3: Two Terraform environments (staging and production)

- [ ] Move the `cloud-design` Terraform code into the independent
      `infrastructure` repository
- [ ] Create the `staging` and `production` environments with the same
      design, resources and services
- [ ] Store the Terraform state remotely, with one state per environment
- [ ] Take no credentials from the Terraform files: everything comes from
      variables or secrets

### Task 4: Infrastructure pipeline

- [ ] `Init`: initialize the working directory, download the providers and
      set up the backend
- [ ] `Validate`: run `terraform fmt -check` and `terraform validate`
- [ ] `Plan`: create the execution plan and keep it as an artifact so it can
      be reviewed
- [ ] `Apply to Staging`: create, update or delete the staging resources
- [ ] `Approval`: add a manual approval step before production
- [ ] `Apply to Production`: create, update or delete the production
      resources
- [ ] Add a manual `destroy` job to delete an environment

### Task 5: Infrastructure security and bonus

- [ ] Only run the pipeline's apply jobs on protected branches
- [ ] Give the pipeline's AWS account the least privilege it needs
- [ ] Store all credentials as masked and protected GitLab variables
- [ ] Bonus: run `tfsec` in the pipeline
- [ ] Bonus: run `Infracost` to estimate the cost of each change
- [ ] Bonus: use `Terragrunt` to manage the environments

---

## Houda's tasks

### Task 6: Application repositories

- [ ] Create the 3 repositories: `inventory-app`, `billing-app`,
      `api-gateway-app`
- [ ] Put the source code and the Dockerfile of each application in its own
      repository
- [ ] Write unit tests for each application
- [ ] Write integration tests (with the database and RabbitMQ)

### Task 7: CI pipeline (in every repository)

- [ ] Trigger it on every push and every merge request
- [ ] `Build`: build and package the application
- [ ] `Test`: run the unit and integration tests
- [ ] `Scan`: scan the code and the dependencies (SonarQube or Snyk)
- [ ] `Containerization`: build the Docker image and push it to the registry
      (AWS ECR)

### Task 8: CD pipeline (in every repository)

- [ ] Trigger it automatically after the CI succeeds
- [ ] `Deploy to Staging`: deploy the new version to staging
- [ ] `Approval`: add a manual approval before production
- [ ] `Deploy to Production`: deploy with zero downtime (rolling update and
      health checks)
- [ ] Check the whole flow: a code change → rebuild → staging → approval →
      production

### Task 9: Application security

- [ ] Protect the `main` branch: merges only through a reviewed merge request
- [ ] Only allow the deploy jobs to run on protected branches
- [ ] Keep no credentials in the code: use masked and protected GitLab
      variables
- [ ] Give the deploy account the least privilege it needs (ECR and ECS only)
- [ ] Keep dependencies and tools up to date automatically (Renovate or
      Dependabot)
- [ ] Scan the Docker images (Trivy)

### Task 10: Documentation and audit

- [ ] Write the final `README.md`: prerequisites, configuration, setup, usage
- [ ] Explain the pipeline design and the tools used, with diagrams
- [ ] Prepare the audit demo: GitLab with Ansible, the pipelines, and a
      deployment to staging and then production
- [ ] Prepare the role play questions and answers

---

## Together

- [ ] Check that everything works end to end before the audit
- [ ] Both understand the whole project, not only our own tasks
- [ ] Destroy unused resources to keep AWS costs down

`FIGHTING AND BE HAPPY`
