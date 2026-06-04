# sethcharleston.com

Static website for `sethcharleston.com`.

## Infrastructure

This repo includes AWS infrastructure as code for the existing static website host:

- Public S3 website bucket `sethcharleston.com`
- CloudFront distribution `E3FWVWV0D2QOJ4`
- Existing ACM certificate for `sethcharleston.com` and `*.sethcharleston.com`
- Route 53 `A` records for `sethcharleston.com` and `www.sethcharleston.com`

The stack is defined in [infra/cloudformation/static-site.yaml](infra/cloudformation/static-site.yaml).

The clean rebuild version of the Lambda backend used by `https://api.sethcharleston.com/test1/...` is defined in [infra/cloudformation/backend-api.yaml](infra/cloudformation/backend-api.yaml). It creates:

- DynamoDB tables for events, music, and editable site text
- One modern Lambda handler for the public read and authenticated admin mutation routes
- REST API Gateway stage `test1`
- Cognito user pool authorizer for admin-only POST routes
- Optional `api.sethcharleston.com` custom domain and Route 53 records

The GitHub-to-AWS deployment path is defined in [infra/cloudformation/codepipeline.yaml](infra/cloudformation/codepipeline.yaml). It creates:

- GitHub source action for `art12354/sethcharleston.com` branch `master`
- CodeBuild package step using [buildspec.yml](buildspec.yml)
- S3 deploy action to the website bucket
- Lambda invoke action to invalidate CloudFront

The package step is important: the legacy live pipeline deploys the entire repository ZIP directly to S3. With IaC in the repo, that would publish `infra/`, `scripts/`, and docs as website files. The new pipeline deploys only `index.html`, page HTML, `sitemap.xml`, `css/`, `photos/`, and `videos/`.

The live production backend currently uses nine Lambda functions instead. The live AWS inventory captured during IaC adoption is documented in [infra/import/live-inventory.md](infra/import/live-inventory.md).

The GitHub-to-CodeCommit mirror is defined in [infra/cloudformation/source-mirror.yaml](infra/cloudformation/source-mirror.yaml). It creates CodeCommit mirrors for this repo and the editor repo, plus a webhook endpoint that can mirror GitHub pushes into AWS-native repositories.

The authenticated editing workflow lives in a sibling repo, `/home/art12354/Projects/edit.sethcharleston.com`. That repo hosts `https://edit.sethcharleston.com`, signs in through `https://login.sethcharleston.com`, and calls the authenticated API mutation routes. Its AWS resources are captured in [infra/import/live-inventory.md](infra/import/live-inventory.md), but its deploy packaging/IaC should live with that repo.

## Prerequisites

Install and configure AWS CLI v2:

```bash
aws configure
aws sts get-caller-identity
```

Use `us-east-1` for this stack. CloudFront custom-domain certificates must be created in `us-east-1`, so the included scripts default to that region.

If the domain is managed by Route 53 in the same AWS account, the deploy script can discover the hosted zone automatically. To check manually:

```bash
aws route53 list-hosted-zones-by-name --dns-name sethcharleston.com
```

## Create Or Update Infra

For a brand-new account, create the backend API first:

```bash
./scripts/deploy-backend.sh
```

The backend stack defaults to the live table names: `seth_charleston_events`, `seth_charleston_music`, and `seth_charleston_text`. In an AWS account where those resources already exist outside CloudFormation, either import them into the stack or override the names:

```bash
EVENTS_TABLE_NAME=seth_charleston_dev_events \
MUSIC_TABLE_NAME=seth_charleston_dev_music \
TEXT_TABLE_NAME=seth_charleston_dev_text \
API_DOMAIN_NAME=api-dev.sethcharleston.com \
./scripts/deploy-backend.sh
```

Then create the static site host:

```bash
./scripts/deploy-infra.sh
```

For the existing production account, do not run `deploy-infra.sh` against the live names until the current resources are imported or intentionally recreated. The static site import mapping is in [infra/import/static-site-resources.json](infra/import/static-site-resources.json). The import flow is:

```bash
aws cloudformation create-change-set \
  --stack-name sethcharleston-static-site \
  --change-set-name import-static-site \
  --change-set-type IMPORT \
  --template-body file://infra/cloudformation/static-site.yaml \
  --resources-to-import file://infra/import/static-site-resources.json \
  --region us-east-1

aws cloudformation describe-change-set \
  --stack-name sethcharleston-static-site \
  --change-set-name import-static-site \
  --region us-east-1

aws cloudformation execute-change-set \
  --stack-name sethcharleston-static-site \
  --change-set-name import-static-site \
  --region us-east-1
```

After import, future changes can go through `./scripts/deploy-infra.sh`.

CloudFormation reports import identifiers for the S3 bucket, S3 bucket policy, and CloudFront distribution. Route 53 record management is present in [infra/cloudformation/static-site.yaml](infra/cloudformation/static-site.yaml), but it is disabled by default with `ManageDnsRecords=false` because the existing records are already live and may not be importable. Enable it only for a fresh zone or after intentionally recreating those records under CloudFormation.

Then create or update the CodePipeline stack. This uses AWS CodeConnections, not legacy GitHub OAuth tokens:

```bash
./scripts/deploy-pipeline.sh
```

The default connection ARN is `arn:aws:codestar-connections:us-east-1:305372771047:connection/6ac1a538-e4aa-4c85-9dce-4b2797063880`. It must be authorized in the AWS Console under Developer Tools > Connections before pipeline creation will work.

There is already a live pipeline named `sethcharleston.com` in the current AWS account. CloudFormation cannot automatically take ownership of an existing manually-created pipeline with the same name. For production, either import that pipeline into the stack or recreate it from [infra/cloudformation/codepipeline.yaml](infra/cloudformation/codepipeline.yaml). For a non-disruptive dry run, deploy the stack with a temporary name:

```bash
PIPELINE_NAME=sethcharleston.com-iac-test \
WEBSITE_BUCKET_NAME=dev.sethcharleston.com \
./scripts/deploy-pipeline.sh
```

Useful static-stack overrides:

```bash
STACK_NAME=sethcharleston-static-site \
AWS_REGION=us-east-1 \
DOMAIN_NAME=sethcharleston.com \
HOSTED_ZONE_ID=Z27ZS6MVE7C6ZT \
ACM_CERTIFICATE_ARN=arn:aws:acm:us-east-1:305372771047:certificate/2db52ae6-5372-472a-b689-42126941926a \
MANAGE_DNS_RECORDS=false \
./scripts/deploy-infra.sh
```

## Deploy The Site

Manual deploy is still available after the stack exists:

```bash
./scripts/deploy-site.sh
```

The deploy script uploads the root static files and media, excludes repo-only files, and invalidates CloudFront.

For normal iteration, commits to `master` should flow through CodePipeline instead:

1. GitHub webhook starts the CodePipeline source action.
2. CodeBuild runs CloudFormation template validation and packages only static website files into `dist/`.
3. CodePipeline deploys the packaged artifact to S3.
4. CodePipeline invokes the existing invalidation Lambda for CloudFront.

Backend/API infrastructure is intentionally not deployed on every commit by this static-site pipeline. Keep backend changes behind explicit `./scripts/deploy-backend.sh` runs or add a separate approved pipeline stage after smoke tests.

## GitHub To CodeCommit Mirror

The source mirror lets GitHub remain the developer-facing remote while AWS owns the CI source repo. This is also the path to moving later from GitHub to Forgejo: change the webhook sender and mirror clone URL, while CodeCommit and CodePipeline can stay stable.

Create or update the mirror resources:

```bash
./scripts/deploy-source-mirror.sh
```

Current mirror resources in this AWS account:

- CodeCommit repos:
  - `sethcharleston.com`
  - `edit.sethcharleston.com`
- Mirror CodeBuild project: `sethcharleston-git-mirror`
- GitHub webhook URL: `https://ow2w607n45.execute-api.us-east-1.amazonaws.com/github`
- GitHub token secret: `sethcharleston/github/mirror-token`
- GitHub webhook secret: `sethcharleston/github/webhook-secret`

Populate the GitHub token secret with a token that can read both GitHub repositories:

```bash
GITHUB_TOKEN=github_pat_or_token_here ./scripts/update-github-mirror-token.sh
```

Configure each GitHub repository webhook:

- Payload URL: use the `WebhookUrl` output from `./scripts/deploy-source-mirror.sh`
- Content type: `application/json`
- Secret: value from `sethcharleston/github/webhook-secret`
- Events: push events

Fetch the webhook secret value only when configuring GitHub:

```bash
aws secretsmanager get-secret-value \
  --secret-id sethcharleston/github/webhook-secret \
  --region us-east-1 \
  --query SecretString \
  --output text
```

Run the initial mirror manually after the token is set:

```bash
REPOSITORY_NAME=sethcharleston.com ./scripts/mirror-github-to-codecommit.sh
REPOSITORY_NAME=edit.sethcharleston.com ./scripts/mirror-github-to-codecommit.sh
```

The staging pipelines and branch-preview automation now use the CodeCommit mirrors as their AWS-native source. Keep production promotion manual.

## End-To-End Staging

The staging environment is built with fresh infrastructure so production can stay untouched until cutover:

- Public site: `https://staging.sethcharleston.com`
- API: `https://api-staging.sethcharleston.com/test1`
- Editor: `https://edit-staging.sethcharleston.com`
- Cognito hosted UI: `https://login-staging.sethcharleston.com`
- DynamoDB tables:
  - `seth_charleston_staging_events`
  - `seth_charleston_staging_music`
  - `seth_charleston_staging_text`

Create or update the full staging environment:

```bash
./scripts/deploy-staging.sh
```

By default the script skips staging CodePipelines and manually packages/deploys the public site and editor content. After the GitHub CodeConnection is authorized, set `DEPLOY_PIPELINES=true` to create/update the staging pipelines. The public site staging pipeline defaults to branch `master`; override with `STAGING_BRANCH=main` if the repo moves to `main`.

```bash
DEPLOY_PIPELINES=true STAGING_BRANCH=master ./scripts/deploy-staging.sh
```

The staging packaging rewrites hard-coded production URLs at deploy time:

- `https://api.sethcharleston.com` -> `https://api-staging.sethcharleston.com`
- `https://login.sethcharleston.com` -> `https://login-staging.sethcharleston.com`
- production Cognito client ID -> staging Cognito client ID
- `https://edit.sethcharleston.com` -> `https://edit-staging.sethcharleston.com`

Useful staging commands:

```bash
./scripts/seed-staging-data.sh
./scripts/deploy-staging-content.sh
./scripts/smoke-test-staging.sh
```

When staging is accepted, cut production DNS to a fresh CloudFront distribution:

```bash
TARGET_STACK_NAME=sethcharleston-fresh-prod-site ./scripts/cutover-production-dns.sh
```

Do that only after creating the final production-shaped fresh stack and confirming its CloudFront distribution has `sethcharleston.com` and `www.sethcharleston.com` aliases. The staging distribution itself uses `staging.sethcharleston.com`, so it is for validation rather than direct production alias cutover.

## Branch Previews

Every non-main branch can get a full DNS-backed preview environment:

- Site: `https://<branch-slug>.sethcharleston.com`
- API: `https://api-<branch-slug>.sethcharleston.com/test1`
- Editor: `https://edit-<branch-slug>.sethcharleston.com`
- Login: `https://login-<branch-slug>.sethcharleston.com`

Deploy the current local branch manually:

```bash
./scripts/deploy-branch.sh
```

Destroy a branch environment:

```bash
BRANCH_NAME=my-feature ./scripts/destroy-branch.sh
```

Deploy the branch-preview automation:

```bash
./scripts/deploy-branch-preview-automation.sh
```

Feature branch automation now follows the same source path as staging:

- GitHub push mirrors into CodeCommit.
- CodeCommit branch create/update events invoke `sethcharleston-branch-preview-starter`.
- The starter runs the `sethcharleston-branch-preview` CodeBuild project for that branch.
- Branch delete events run the destroy path for the matching preview environment.

The EventBridge/Lambda starter excludes `main` and `master`; those branches deploy through staging instead. To start a branch preview build manually from CodeBuild, set `BRANCH_NAME` to the branch and `PREVIEW_ACTION` to `deploy` or `destroy`.

## Production Promotion

The existing production pipeline `sethcharleston.com` has been locked so pushes no longer transition automatically into the production `Deploy` stage:

```bash
./scripts/lock-production-pipeline.sh
```

Production promotion is manual. For the legacy pipeline path, unlock it only when you intentionally want that pipeline to deploy:

```bash
./scripts/unlock-production-pipeline.sh
```

For the fresh-stack path, validate staging first, create the production-shaped fresh stack, then run:

```bash
TARGET_STACK_NAME=sethcharleston-fresh-prod-site ./scripts/cutover-production-dns.sh
```

## Existing Backend Adoption

The live backend uses REST API Gateway plus nine Lambda functions. The extracted Lambda handlers are now in [backend/lambda](backend/lambda), but the current backend CloudFormation template is still the clean rebuild path, not a one-click import of every live backend resource. The admin UI that exercises the authenticated routes is the sibling repo at `/home/art12354/Projects/edit.sethcharleston.com`.

Before putting the live backend fully under CloudFormation, use [infra/import/live-inventory.md](infra/import/live-inventory.md) as the adoption checklist:

- Import or recreate the three DynamoDB tables.
- Import or recreate the Cognito user pool and app client.
- Import or recreate the REST API Gateway resources, methods, authorizer, custom domain, and base path mapping.
- Import or recreate each Lambda function and IAM role.
- Modernize `nodejs8.10` and `nodejs14.x` functions only after they are under source control and a dev stage has passed smoke tests.

The current production API endpoints should be smoke-tested after every backend IaC change:

```bash
curl -f https://api.sethcharleston.com/test1/
curl -f https://api.sethcharleston.com/test1/text
curl -f https://api.sethcharleston.com/test1/songs
```

## Backend API Contract

The frontend currently calls these API routes under the `test1` stage:

- `GET /test1/` returns `{ "Items": [...] }` for show/event data.
- `GET /test1/text` returns an array of `{ "location", "text" }` records.
- `GET /test1/songs` returns an array of `{ "song", "release", "link" }` records.
- `POST /test1/`, `POST /test1/text`, `POST /test1/songs`, `POST /test1/delete`, and `POST /test1/delete_song` require a Cognito bearer token.
- `GET /test1/access` requires a Cognito bearer token and can be used by an admin UI as a token check.

To create an admin user after deploying the backend:

```bash
USER_POOL_ID=$(aws cloudformation describe-stacks \
  --stack-name sethcharleston-backend-api \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue | [0]" \
  --output text)

aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username admin@example.com \
  --user-attributes Name=email,Value=admin@example.com Name=email_verified,Value=true \
  --region us-east-1
```

## Hidden Runtime Assumptions

This repository only contains the static frontend. The pages also depend on services outside this repo:

- `https://store.sethcharleston.com`
- Third-party scripts and embeds from Google Analytics, Facebook, Mailchimp, Spotify, Font Awesome, and Google Fonts

The clean rebuild API infrastructure is represented in this repo. The live production backend still needs a deliberate import/migration pass before CloudFormation owns every existing API resource. DynamoDB tables in a new environment start empty; migrate or seed content if you need that environment to show the same events, music embeds, and editable text as production.

## Teardown

The S3 and DynamoDB resources are retained by CloudFormation to avoid accidental data loss. To remove the stacks:

```bash
aws cloudformation delete-stack \
  --stack-name sethcharleston-backend-api \
  --region us-east-1

aws cloudformation delete-stack \
  --stack-name sethcharleston-static-site \
  --region us-east-1
```

Empty and delete the retained buckets and tables manually only when you are sure the site data and logs are no longer needed.
