#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
BACKUP_ID="${BACKUP_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
BACKUP_PREFIX="${BACKUP_PREFIX:-production-backups/${BACKUP_ID}}"

echo "Creating production backups with id ${BACKUP_ID}."

for table in seth_charleston_events seth_charleston_music seth_charleston_text; do
  aws dynamodb create-backup \
    --table-name "$table" \
    --backup-name "${table}-${BACKUP_ID}" \
    --region "$AWS_REGION" \
    --query "BackupDetails.BackupArn" \
    --output text
done

for bucket in sethcharleston.com edit.sethcharleston.com; do
  aws s3 sync "s3://${bucket}/" "s3://${bucket}/${BACKUP_PREFIX}/${bucket}/" --only-show-errors
  echo "Backed up s3://${bucket}/ to s3://${bucket}/${BACKUP_PREFIX}/${bucket}/"
done

echo "Production backup requests created."
