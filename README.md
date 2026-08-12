# sethcharleston.com

Public website and private editor for `sethcharleston.com`, hosted in AWS and deployed by GitHub Actions. The editor source lives in [`editor/`](editor/).

## Environments

| Environment | Trigger | URL | API |
| --- | --- | --- | --- |
| Branch preview | Push to any feature branch | `https://<branch-slug>.sethcharleston.com` | Staging |
| Staging | Push or merge to `master` | `https://staging.sethcharleston.com` | Staging |
| Production | Manual GitHub Actions promotion from `master` | `https://sethcharleston.com` | Production |

Feature branch names are lowercased, converted to DNS-safe slugs, and limited to 42 characters. Deleting a branch automatically deletes its preview stack, bucket, CloudFront distribution, and DNS record.

## CI/CD

The workflows are intentionally small:

- [deploy-preview.yml](.github/workflows/deploy-preview.yml) creates, updates, and removes feature-branch previews.
- [deploy-staging.yml](.github/workflows/deploy-staging.yml) automatically publishes `master` to staging and runs smoke tests.
- [deploy-production.yml](.github/workflows/deploy-production.yml) manually promotes `master` to production and runs a smoke test.

GitHub authenticates to AWS with short-lived OIDC credentials. No AWS access keys are stored in GitHub. The repository variables are:

- `AWS_DEPLOY_ROLE_ARN` for staging and production uploads.
- `AWS_PREVIEW_ROLE_ARN` for disposable preview infrastructure.

The deploy role can write only the staging and production website buckets and invalidate their two CloudFront distributions. The preview role is separate and limited to `sethcharleston-branch-*-site` CloudFormation stacks, preview buckets under `*.sethcharleston.com`, CloudFront, and the site's Route 53 zone.

Bootstrap or update the roles and repository variables with:

```bash
./scripts/deploy-github-actions-access.sh
```

The supporting CloudFormation template is [github-actions-deploy.yaml](infra/cloudformation/github-actions-deploy.yaml).

## Deployment behavior

Only these website files are published:

- Root HTML files and `sitemap.xml`
- `css/`
- `photos/`
- `videos/`

HTML and the sitemap use a five-minute cache policy. Static assets use a one-day cache policy. Each deployment invalidates the relevant CloudFront distribution.

Branch and staging builds replace the production API origin in HTML with `https://api-staging.sethcharleston.com`. Production keeps `https://api.sethcharleston.com`.

To manually start a production promotion:

```bash
gh workflow run deploy-production.yml --ref master
```

To watch it:

```bash
gh run watch
```

## AWS footprint

The public site requires:

- S3 website buckets
- CloudFront distributions
- Route 53 records
- One ACM wildcard certificate in `us-east-1`
- Two GitHub Actions IAM roles and one GitHub OIDC provider

The application backend additionally uses API Gateway, Lambda, DynamoDB, and Cognito. These runtime services remain in AWS; CI services are not required for the public site.

The production static site is managed by [static-site.yaml](infra/cloudformation/static-site.yaml). Disposable previews use [preview-static-site.yaml](infra/cloudformation/preview-static-site.yaml), which deliberately does not retain branch resources on deletion.

The production backend currently uses nine Lambda functions. Its adopted infrastructure and inventory are documented in [live-inventory.md](infra/import/live-inventory.md), [live-backend-foundation.yaml](infra/cloudformation/live-backend-foundation.yaml), and [live-api-gateway.yaml](infra/cloudformation/live-api-gateway.yaml).

The former `edit.sethcharleston.com` repository has been merged into [`editor/`](editor/). Staging and production workflows publish the public site and editor together from this repository.

The editor is packaged from the same `index.html`, `about.html`, `music.html`, `shows.html`, `css/`, and media files as the public site. [`package-editor.sh`](scripts/package-editor.sh) adds only the authenticated inline-editing controls, keeping the editor presentation synchronized with the live pages.

## Manual infrastructure commands

Use `us-east-1`; CloudFront custom-domain certificates must be in that region.

Deploy or update a non-production static site stack:

```bash
STACK_NAME=sethcharleston-staging-site \
DOMAIN_NAME=staging.sethcharleston.com \
HOSTED_ZONE_ID=Z27ZS6MVE7C6ZT \
MANAGE_DNS_RECORDS=true \
INCLUDE_WWW_ALIAS=false \
./scripts/deploy-infra.sh
```

Do not run the generic infrastructure scripts against existing production names unless the resources are already imported into the corresponding CloudFormation stack. Import mappings and the captured production inventory live under `infra/import/`.

Useful operational scripts include:

- `scripts/deploy-infra.sh` for static hosting infrastructure.
- `scripts/deploy-backend.sh` for the clean-rebuild backend stack.
- `scripts/backup-production.sh` for production data backups.
- `scripts/create-admin-user.sh` for Cognito administrators.
- `scripts/smoke-test-staging.sh` for staging endpoint checks.
