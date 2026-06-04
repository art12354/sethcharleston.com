# Live AWS Inventory

Captured from AWS account `305372771047` in `us-east-1`.

## Static Site

- S3 bucket: `sethcharleston.com`
- S3 website index document: `index.html`
- S3 website error document: `error.html`
- S3 bucket policy: public `s3:GetObject` on `arn:aws:s3:::sethcharleston.com/*`
- CloudFront distribution: `E3FWVWV0D2QOJ4`
- CloudFront domain: `d2k5yj6uwh8wot.cloudfront.net`
- CloudFront origin: `sethcharleston.com.s3-website-us-east-1.amazonaws.com`
- ACM certificate: `arn:aws:acm:us-east-1:305372771047:certificate/2db52ae6-5372-472a-b689-42126941926a`
- Route 53 hosted zone: `Z27ZS6MVE7C6ZT`
- Website records: `sethcharleston.com A`, `www.sethcharleston.com A`

## CodePipeline

- Pipeline: `sethcharleston.com`
- Source: GitHub `art12354/sethcharleston.com`, branch `master`
- Deploy target bucket: `sethcharleston.com`
- Invalidation function: `seth_charleston_invalidate_cdn`
- Distribution ID passed to invalidation function: `E3FWVWV0D2QOJ4`

The live pipeline currently deploys the entire source artifact directly to S3. The IaC pipeline template adds a CodeBuild package stage so repo-only files are not published.

## Admin Editor Repo

The production site depends on a separate admin editor repository:

- Local path: `/home/art12354/Projects/edit.sethcharleston.com`
- GitHub repo: `art12354/edit.sethcharleston.com`
- Public URL: `https://edit.sethcharleston.com`
- S3 bucket: `edit.sethcharleston.com`
- CloudFront distribution: `E2XF0OI690268U`
- CloudFront domain: `d3mqcyj44ytld1.cloudfront.net`
- Route 53 record: `edit.sethcharleston.com A`
- Pipeline: `edit.sethcharleston.com`
- Pipeline source branch: `master`
- Pipeline deploy target bucket: `edit.sethcharleston.com`
- Pipeline invalidation function: `seth_charleston_invalidate_cdn`
- Distribution ID passed to invalidation function: `E2XF0OI690268U`

The editor app signs in through Cognito hosted UI:

- Hosted UI domain: `login.sethcharleston.com`
- User pool: `us-east-1_KyvNSufwI`
- App client ID: `76g2um3ps3ri68ac30agopcmc9`
- Callback URL: `https://edit.sethcharleston.com`
- OAuth flows: `code`, `implicit`
- OAuth scopes: `email`, `openid`

The editor app is the admin UI for the backend mutation routes:

- `GET https://api.sethcharleston.com/test1/access`
- `POST https://api.sethcharleston.com/test1`
- `POST https://api.sethcharleston.com/test1/text/`
- `POST https://api.sethcharleston.com/test1/songs`
- `POST https://api.sethcharleston.com/test1/delete`
- `POST https://api.sethcharleston.com/test1/delete_song`

## Backend API

- API Gateway REST API: `ht1utrpnua`
- API name: `seth_charleston_events`
- Stage: `test1`
- API custom domain: `api.sethcharleston.com`
- API Gateway distribution domain: `d4kywkuh2lcxu.cloudfront.net`
- Cognito user pool: `us-east-1_KyvNSufwI`
- Cognito app client: `76g2um3ps3ri68ac30agopcmc9`
- Cognito hosted UI domain: `login.sethcharleston.com`
- Cognito authorizer ID: `z3qept`
- DynamoDB tables:
  - `seth_charleston_events`, key `event`
  - `seth_charleston_music`, key `song`
  - `seth_charleston_text`, key `location`
- Lambda functions:
  - `seth_charleston_get_events`, `nodejs18.x`
  - `seth_charleston_post_events`, `nodejs18.x`
  - `seth_charleston_delete_events`, `nodejs18.x`
  - `seth_charleston_get_songs`, `nodejs8.10`
  - `seth_charleston_post_song`, `nodejs8.10`
  - `seth_charleston_delete_songs`, `nodejs8.10`
  - `seth_charleston_get_text`, `nodejs14.x`
  - `seth_charleston_post_text`, `nodejs14.x`
  - `seth_charleston_invalidate_cdn`, `nodejs18.x`

The Lambda source extracted from the live functions is stored under `backend/lambda/`.
