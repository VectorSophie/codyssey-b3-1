#!/bin/bash
# teardown.sh — codyssey-b6-1 리소스 일괄 삭제
# 사용법: bash scripts/teardown.sh <VPC_ID> <INSTANCE_ID> <IGW_ID> <RTB_ID> <SG_ID> <SUBNET_ID>
# provision.sh 완료 시 출력되는 teardown 명령을 그대로 붙여넣으면 됨

set -euo pipefail

REGION="ap-northeast-2"
PROFILE="b6user"
AWS="aws --profile $PROFILE --region $REGION"
log() { echo "[$(date +%H:%M:%S)] $*"; }

VPC_ID="${1:?VPC_ID 필요}"
INSTANCE_ID="${2:?INSTANCE_ID 필요}"
IGW_ID="${3:?IGW_ID 필요}"
RTB_ID="${4:?RTB_ID 필요}"
SG_ID="${5:?SG_ID 필요}"
SUBNET_ID="${6:?SUBNET_ID 필요}"

log "EC2 종료 중: $INSTANCE_ID"
$AWS ec2 terminate-instances --instance-ids "$INSTANCE_ID" > /dev/null
$AWS ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
log "EC2 종료 완료"

log "Security Group 삭제: $SG_ID"
$AWS ec2 delete-security-group --group-id "$SG_ID"

log "Subnet 삭제: $SUBNET_ID"
$AWS ec2 delete-subnet --subnet-id "$SUBNET_ID"

log "Route Table 삭제: $RTB_ID"
$AWS ec2 delete-route-table --route-table-id "$RTB_ID"

log "IGW 분리 및 삭제: $IGW_ID"
$AWS ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
$AWS ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"

log "VPC 삭제: $VPC_ID"
$AWS ec2 delete-vpc --vpc-id "$VPC_ID"

log "정리 완료"
