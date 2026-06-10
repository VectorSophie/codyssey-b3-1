#!/bin/bash
# provision.sh — codyssey-b6-1 AWS 인프라 자동화 스크립트
# 사용법: bash scripts/provision.sh
# 전제: aws cli 설치, --profile b6user 설정 완료

set -euo pipefail

REGION="ap-northeast-2"
PROFILE="b6user"
PROJECT="codyssey-b6-1"
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
AZ="${REGION}a"
INSTANCE_TYPE="t3.micro"
AMI_ID="ami-042e76978adeb8c48"   # Ubuntu 22.04 LTS ap-northeast-2
KEY_NAME="b6-keypair"
MY_IP=$(curl -s https://checkip.amazonaws.com)/32

AWS="aws --profile $PROFILE --region $REGION"
log() { echo "[$(date +%H:%M:%S)] $*"; }

# ── VPC ──────────────────────────────────────────────────
log "VPC 생성 중..."
VPC_ID=$($AWS ec2 create-vpc --cidr-block "$VPC_CIDR" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=b6-vpc},{Key=Project,Value=$PROJECT}]" \
  --query 'Vpc.VpcId' --output text)
$AWS ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
log "VPC: $VPC_ID"

# ── Subnet ───────────────────────────────────────────────
log "서브넷 생성 중..."
SUBNET_ID=$($AWS ec2 create-subnet --vpc-id "$VPC_ID" \
  --cidr-block "$SUBNET_CIDR" --availability-zone "$AZ" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=b6-public-subnet},{Key=Project,Value=$PROJECT}]" \
  --query 'Subnet.SubnetId' --output text)
log "Subnet: $SUBNET_ID"

# ── Internet Gateway ─────────────────────────────────────
log "인터넷 게이트웨이 연결 중..."
IGW_ID=$($AWS ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=b6-igw},{Key=Project,Value=$PROJECT}]" \
  --query 'InternetGateway.InternetGatewayId' --output text)
$AWS ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
log "IGW: $IGW_ID"

# ── Route Table ──────────────────────────────────────────
log "라우팅 테이블 구성 중..."
RTB_ID=$($AWS ec2 create-route-table --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=b6-rtb},{Key=Project,Value=$PROJECT}]" \
  --query 'RouteTable.RouteTableId' --output text)
$AWS ec2 create-route --route-table-id "$RTB_ID" \
  --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" > /dev/null
$AWS ec2 associate-route-table --route-table-id "$RTB_ID" \
  --subnet-id "$SUBNET_ID" > /dev/null
log "Route Table: $RTB_ID"

# ── Security Group ───────────────────────────────────────
log "보안 그룹 생성 중..."
SG_ID=$($AWS ec2 create-security-group \
  --group-name b6-sg --description "b6-1 HTTP+SSH" \
  --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=b6-sg},{Key=Project,Value=$PROJECT}]" \
  --query 'GroupId' --output text)
$AWS ec2 authorize-security-group-ingress --group-id "$SG_ID" \
  --ip-permissions \
  'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]' \
  "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$MY_IP}]" > /dev/null
log "Security Group: $SG_ID (SSH 허용 IP: $MY_IP)"

# ── Key Pair ─────────────────────────────────────────────
log "키페어 생성 중..."
if [ ! -f "${KEY_NAME}.pem" ]; then
  $AWS ec2 create-key-pair --key-name "$KEY_NAME" \
    --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
  log "키페어 저장: ${KEY_NAME}.pem"
else
  log "키페어 이미 존재: ${KEY_NAME}.pem"
fi

# ── EC2 ──────────────────────────────────────────────────
log "EC2 인스턴스 시작 중..."
INSTANCE_ID=$($AWS ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --associate-public-ip-address \
  --user-data file://scripts/user-data.sh \
  --tag-specifications \
    "ResourceType=instance,Tags=[{Key=Name,Value=b6-server},{Key=Project,Value=$PROJECT}]" \
  --query 'Instances[0].InstanceId' --output text)
log "Instance: $INSTANCE_ID — running 대기 중..."

$AWS ec2 wait instance-running --instance-ids "$INSTANCE_ID"
PUBLIC_IP=$($AWS ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
log "EC2 실행 완료: $PUBLIC_IP"

# ── 헬스체크 ─────────────────────────────────────────────
log "Nginx 초기화 대기 (75초)..."
sleep 75

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${PUBLIC_IP}/health" || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
  log "헬스체크 통과: GET http://${PUBLIC_IP}/health → $HTTP_CODE"
else
  log "WARNING: 헬스체크 응답 $HTTP_CODE (Nginx 미완료일 수 있음. 잠시 후 재시도)"
fi

# ── 요약 ─────────────────────────────────────────────────
echo ""
echo "========================================"
echo " 프로비저닝 완료"
echo "========================================"
echo " VPC:             $VPC_ID"
echo " Subnet:          $SUBNET_ID"
echo " IGW:             $IGW_ID"
echo " Route Table:     $RTB_ID"
echo " Security Group:  $SG_ID"
echo " EC2 Instance:    $INSTANCE_ID"
echo " Public IP:       $PUBLIC_IP"
echo " Health:          http://${PUBLIC_IP}/health"
echo "========================================"
echo " 정리: bash scripts/teardown.sh $VPC_ID $INSTANCE_ID $IGW_ID $RTB_ID $SG_ID $SUBNET_ID"
