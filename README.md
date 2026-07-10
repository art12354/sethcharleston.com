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
- Cognito email password recovery and admin email allowlist
- Optional `api.sethcharleston.com` custom domain and Route 53 records

The GitHub-to-AWS deployment path is defined in [infra/cloudformation/codepipeline.yaml](infra/cloudformation/codepipeline.yaml). It creates:

- GitHub source action for `art12354/sethcharleston.com` branch `master`
- CodeBuild package step using [buildspec.yml](buildspec.yml)
- S3 deploy action to the website bucket
- Lambda invoke action to invalidate CloudFront

The package step is important: the legacy live pipeline deploys the entire repository ZIP directly to S3. With IaC in the repo, that would publish `infra/`, `scripts/`, and docs as website files. The new pipeline deploys only `index.html`, page HTML, `sitemap.xml`, `css/`, `photos/`, and `videos/`.

The live production backend uses the imported legacy shape and is managed by CloudFormation in two stacks:

- [infra/cloudformation/live-backend-foundation.yaml](infra/cloudformation/live-backend-foundation.yaml): DynamoDB tables, Cognito user pool/client, and the nine production Lambda functions
- [infra/cloudformation/live-api-gateway.yaml](infra/cloudformation/live-api-gateway.yaml): REST API Gateway, `test1` stage, Cognito authorizer, `api.sethcharleston.com` custom domain, and base path mapping

The live AWS inventory captured during IaC adoption is documented in [infra/import/live-inventory.md](infra/import/live-inventory.md).

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
ALLOWED_ADMIN_EMAILS=art12354@gmail.com,seth.charleston@gmail.com \
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

For normal iteration, commits to `master` flow through the GitHub-to-CodeCommit mirror and the staging CodePipeline:

1. GitHub webhook invokes the mirror endpoint.
2. The mirror CodeBuild project pushes GitHub refs into the CodeCommit mirror.
3. A CodeCommit branch update EventBridge rule starts the staging CodePipeline.
4. CodeBuild runs CloudFormation template validation and packages only static website files into `dist/`.
5. CodePipeline deploys the packaged artifact to S3.
6. CodePipeline invokes the existing invalidation Lambda for CloudFront.

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

The staging pipelines and branch-preview automation use the CodeCommit mirrors as their AWS-native source. Production pipelines are also CodeCommit-sourced, but source-change triggers are disabled so promotion stays manual.

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

By default the script skips staging CodePipelines and manually packages/deploys the public site and editor content. Set `DEPLOY_PIPELINES=true` to create/update the staging pipelines. The public site staging pipeline defaults to branch `master`; override with `STAGING_BRANCH=main` if the repo moves to `main`.

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

Current staging automation:

- `sethcharleston.com-staging` reads `master` from the `sethcharleston.com` CodeCommit mirror and is started by a CodeCommit EventBridge rule.
- `edit.sethcharleston.com-staging` reads `master` from the `edit.sethcharleston.com` CodeCommit mirror and is started by a CodeCommit EventBridge rule.

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

### Playwright preview evaluation

Use this when an agent needs a quick browser-level check of the current feature branch deployment. The preview host convention is:

```bash
branch="$(git branch --show-current)"
base_url="https://${branch}.sethcharleston.com"
```

First confirm CloudFront is serving the branch preview:

```bash
curl -I -L --max-time 20 "$base_url"
```

Run Playwright from the repo's Nix shell. The base environment does not necessarily have `node` or `npm` on `PATH`, and the Nix shell provides the pinned Chromium executable through `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`.

```bash
nix-shell --run 'tmpdir=$(mktemp -d /tmp/seth-pw.XXXXXX) && npm --prefix "$tmpdir" install playwright@latest >/dev/null && NODE_PATH="$tmpdir/node_modules" node <<'"'"'NODE'"'"'
const { chromium } = require("playwright");
const branch = process.env.BRANCH_NAME || require("child_process").execSync("git branch --show-current", { encoding: "utf8" }).trim();
const base = `https://${branch}.sethcharleston.com`;
const paths = ["/", "/about.html", "/music.html", "/shows.html"];
const viewports = [
  { name: "mobile", width: 390, height: 844 },
  { name: "tablet", width: 768, height: 1024 },
  { name: "desktop", width: 1440, height: 1000 }
];

(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH,
    headless: true
  });
  const results = [];

  for (const viewport of viewports) {
    const context = await browser.newContext({ viewport });
    for (const path of paths) {
      const page = await context.newPage();
      const consoleMessages = [];
      const failedRequests = [];
      const badResponses = [];

      page.on("console", msg => {
        if (["error", "warning"].includes(msg.type())) consoleMessages.push(`${msg.type()}: ${msg.text()}`);
      });
      page.on("requestfailed", req => failedRequests.push(`${req.method()} ${req.url()} -> ${req.failure()?.errorText || "failed"}`));
      page.on("response", res => {
        if (res.status() >= 400) badResponses.push(`${res.status()} ${res.url()}`);
      });

      const response = await page.goto(new URL(path, base).href, { waitUntil: "networkidle", timeout: 30000 });
      const metrics = await page.evaluate(() => {
        const doc = document.documentElement;
        const body = document.body;
        const images = Array.from(document.images).map(img => ({
          src: img.currentSrc || img.src,
          complete: img.complete,
          naturalWidth: img.naturalWidth,
          naturalHeight: img.naturalHeight
        }));
        const overflowing = Array.from(document.querySelectorAll("body *")).filter(el => {
          const r = el.getBoundingClientRect();
          return r.width > 0 && r.height > 0 && (r.right > window.innerWidth + 1 || r.left < -1);
        }).slice(0, 10).map(el => ({
          tag: el.tagName,
          className: el.className,
          text: el.textContent.trim().slice(0, 80),
          rect: el.getBoundingClientRect()
        }));

        return {
          title: document.title,
          bodyChars: body.innerText.trim().length,
          scrollWidth: Math.max(doc.scrollWidth, body.scrollWidth),
          innerWidth: window.innerWidth,
          brokenImages: images.filter(img => !img.complete || img.naturalWidth === 0 || img.naturalHeight === 0),
          overflowing
        };
      });

      results.push({
        viewport: viewport.name,
        path,
        status: response?.status(),
        ...metrics,
        consoleMessages,
        failedRequests,
        badResponses
      });
      await page.close();
    }
    await context.close();
  }

  await browser.close();
  console.log(JSON.stringify(results, null, 2));
})();
NODE'
```

Review the output for non-200 statuses, empty `bodyChars`, `badResponses`, `failedRequests`, `brokenImages`, and real layout overflow. Google Tag Manager failures can appear as `net::ERR_CONNECTION_REFUSED` in restricted agent environments; treat that as an environment note unless the same failure reproduces from a normal browser.

## Production Promotion

Production uses separate CodeCommit-sourced pipelines with source-change triggers disabled and manual approval enabled:

- `sethcharleston.com-production`
- `edit.sethcharleston.com-production`

Create or update those production pipelines with:

```bash
./scripts/deploy-production-pipelines.sh
```

Production promotion is manual. Start the appropriate production pipeline only after staging has passed smoke tests, then approve the deploy stage in CodePipeline.

The older lock/unlock scripts are kept for the legacy production pipeline path:

```bash
./scripts/lock-production-pipeline.sh
./scripts/unlock-production-pipeline.sh
```

For the fresh-stack DNS cutover path, validate staging first, create the production-shaped fresh stack, then run:

```bash
TARGET_STACK_NAME=sethcharleston-fresh-prod-site ./scripts/cutover-production-dns.sh
```

## Production Backend

The live backend uses REST API Gateway plus nine Lambda functions. It has been imported into CloudFormation and is managed by these production stacks:

- `sethcharleston-prod-backend-foundation`
- `sethcharleston-prod-live-api-gateway`

The imported-production templates are [infra/cloudformation/live-backend-foundation.yaml](infra/cloudformation/live-backend-foundation.yaml) and [infra/cloudformation/live-api-gateway.yaml](infra/cloudformation/live-api-gateway.yaml). The clean rebuild template, [infra/cloudformation/backend-api.yaml](infra/cloudformation/backend-api.yaml), is still useful for fresh environments and modernization work, but it is not the template currently backing production.

The extracted Lambda handlers are in [backend/lambda](backend/lambda). The admin UI that exercises the authenticated routes is the sibling repo at `/home/art12354/Projects/edit.sethcharleston.com`.

Before changing production backend resources:

- Confirm stack drift for `sethcharleston-prod-backend-foundation` and `sethcharleston-prod-live-api-gateway`.
- Smoke-test a non-production environment first when changing Lambda runtime behavior, API Gateway integrations, or Cognito settings.
- Modernize the remaining legacy Lambda runtimes only after the equivalent staging or branch environment has passed smoke tests.

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
STACK_NAME=sethcharleston-staging-backend \
ADMIN_EMAIL=art12354@gmail.com \
./scripts/create-admin-user.sh
```

The backend user pool enables password reset through verified email. Admin-created users must be `CONFIRMED` before the hosted forgot-password flow works, so `create-admin-user.sh` sets an unprinted random permanent password by default; the user should then use forgot password in the hosted UI. Admin users are restricted by `AllowedAdminEmails`, which defaults to `art12354@gmail.com,seth.charleston@gmail.com`; override `ALLOWED_ADMIN_EMAILS` when deploying if that list changes. Public self-signup remains disabled.

## Hidden Runtime Assumptions

This repository only contains the static frontend. The pages also depend on services outside this repo:

- `https://store.sethcharleston.com`
- Third-party scripts and embeds from Google Analytics, Facebook, Mailchimp, Spotify, Font Awesome, and Google Fonts

Both the imported live production backend and the clean rebuild API infrastructure are represented in this repo. DynamoDB tables in a new environment start empty; migrate or seed content if you need that environment to show the same events, music embeds, and editable text as production.

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
