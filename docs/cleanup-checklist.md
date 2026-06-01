# 리소스 정리 체크리스트 — b6-1

> **실습 종료 후 반드시 순서대로 실행**할 것. 역순으로 삭제해야 의존성 오류가 없다.
> 모든 명령: `--profile b6user --region ap-northeast-2`

---

## 리소스 식별 정보

| 리소스 | ID |
|---|---|
| EC2 인스턴스 | `i-05d106a3c3409edd4` |
| EBS 볼륨 | (인스턴스 종료 후 확인) |
| Security Group | `sg-06a53efc080f4c3c6` |
| Public Subnet | `subnet-01c319e79337bc3b0` |
| Route Table | `rtb-05896b293836ba38e` |
| Internet Gateway | `igw-0216170a9e1876f6f` |
| VPC | `vpc-023d852a3471ef158` |
| Key Pair | `b6-keypair` |
| IAM User | `codyssey-b6-user` |
| IAM Access Key | `AKIAUXZY3NKTUZW4TSVO` |

---

## 정리 절차

### 1. EC2 인스턴스 종료

```bash
aws ec2 terminate-instances \
  --instance-ids i-05d106a3c3409edd4 \
  --profile b6user --region ap-northeast-2

# 종료 완료 대기
aws ec2 wait instance-terminated \
  --instance-ids i-05d106a3c3409edd4 \
  --profile b6user --region ap-northeast-2
```

- [ ] EC2 상태 `terminated` 확인

### 2. EBS 볼륨 삭제 (인스턴스 종료 후)

```bash
# 미사용 볼륨 확인
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --profile b6user --region ap-northeast-2 \
  --query 'Volumes[*].[VolumeId,Size,State]' --output table

# 볼륨 삭제 (VOLUME_ID는 위에서 확인)
# aws ec2 delete-volume --volume-id <VOLUME_ID> \
#   --profile b6user --region ap-northeast-2
```

- [ ] 미사용 EBS 볼륨 없음 확인

### 3. Elastic IP 확인 및 해제 (할당한 경우)

```bash
aws ec2 describe-addresses \
  --profile b6user --region ap-northeast-2
```

- [ ] Elastic IP 없음 확인 (이번 실습에서 미사용, 자동 배정 퍼블릭 IP 사용)

### 4. 키페어 삭제

```bash
aws ec2 delete-key-pair --key-name b6-keypair \
  --profile b6user --region ap-northeast-2
```

- [ ] 키페어 삭제 완료
- [ ] `b6-keypair.pem` 로컬 파일 삭제 (git에 포함되지 않음)

### 5. Security Group 삭제

```bash
aws ec2 delete-security-group \
  --group-id sg-06a53efc080f4c3c6 \
  --profile b6user --region ap-northeast-2
```

- [ ] Security Group 삭제 완료

### 6. Subnet 삭제

```bash
aws ec2 delete-subnet \
  --subnet-id subnet-01c319e79337bc3b0 \
  --profile b6user --region ap-northeast-2
```

- [ ] Subnet 삭제 완료

### 7. Route Table 삭제 (서브넷 연결 해제 후)

```bash
# 연결 해제
aws ec2 disassociate-route-table \
  --association-id rtbassoc-02da8b0e4b675fb29 \
  --profile b6user --region ap-northeast-2

# Route Table 삭제
aws ec2 delete-route-table \
  --route-table-id rtb-05896b293836ba38e \
  --profile b6user --region ap-northeast-2
```

- [ ] Route Table 삭제 완료

### 8. Internet Gateway 분리 및 삭제

```bash
aws ec2 detach-internet-gateway \
  --internet-gateway-id igw-0216170a9e1876f6f \
  --vpc-id vpc-023d852a3471ef158 \
  --profile b6user --region ap-northeast-2

aws ec2 delete-internet-gateway \
  --internet-gateway-id igw-0216170a9e1876f6f \
  --profile b6user --region ap-northeast-2
```

- [ ] Internet Gateway 삭제 완료

### 9. VPC 삭제

```bash
aws ec2 delete-vpc \
  --vpc-id vpc-023d852a3471ef158 \
  --profile b6user --region ap-northeast-2
```

- [ ] VPC 삭제 완료

### 10. IAM 정리 (루트 계정으로 실행)

```bash
# Access Key 비활성화/삭제
aws iam delete-access-key \
  --user-name codyssey-b6-user \
  --access-key-id AKIAUXZY3NKTUZW4TSVO

# 인라인 정책 삭제
aws iam delete-user-policy \
  --user-name codyssey-b6-user \
  --policy-name B6LabMinimumPrivilege

# 유저 삭제
aws iam delete-user --user-name codyssey-b6-user
```

- [ ] IAM Access Key 삭제
- [ ] IAM 인라인 정책 삭제
- [ ] IAM 유저 `codyssey-b6-user` 삭제

---

## 추가 확인 항목

- [ ] NAT Gateway 없음 (미사용)
- [ ] ELB/ALB 없음 (미사용)
- [ ] RDS 없음 (미사용)
- [ ] Billing Dashboard 확인 — 과금 항목 없음

---

## 정리 완료 확인 명령

```bash
# 남은 리소스 일괄 확인
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=codyssey-b6-1" \
  --profile b6user --region ap-northeast-2 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=codyssey-b6-1" \
  --profile b6user --region ap-northeast-2 \
  --query 'Vpcs[*].VpcId' --output text
```
