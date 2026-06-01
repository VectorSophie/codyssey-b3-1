# 트러블슈팅 보고서 — b6-1

## 건 1: t2.micro로 EC2 실행 실패 (InvalidParameterCombination)

| 항목 | 내용 |
|---|---|
| **증상** | `aws ec2 run-instances --instance-type t2.micro` 실행 시 `InvalidParameterCombination` 에러 발생 |
| **에러 메시지** | `The specified instance type is not eligible for Free Tier. For a list of Free Tier instance types, run 'describe-instance-types' with the filter 'free-tier-eligible=true'.` |
| **원인 가설** | 과제 스펙에 t2.micro가 권장 인스턴스로 언급되어 있으나, ap-northeast-2 리전에서 해당 계정의 프리 티어 대상 인스턴스가 달라졌을 가능성 |
| **검증 방법** | `aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true" --region ap-northeast-2` 실행으로 실제 프리 티어 대상 목록 조회 |
| **검증 결과** | ap-northeast-2에서 Free Tier 대상: `t3.micro`, `t4g.micro`, `t3.small`, `t4g.small`, `c7i-flex.large`, `m7i-flex.large` — t2.micro는 포함되지 않음 |
| **조치** | `--instance-type t2.micro` → `--instance-type t3.micro` 로 변경 후 재실행 |
| **결과** | EC2 인스턴스 정상 생성 (i-05d106a3c3409edd4) |
| **재발 방지** | 인스턴스 타입 선택 전 `describe-instance-types --filters free-tier-eligible=true`로 해당 리전 대상 확인을 체크리스트에 추가 |

---

## 건 2: EC2 기동 직후 /health 응답 없음 (서비스 부팅 대기)

| 항목 | 내용 |
|---|---|
| **증상** | EC2가 `running` 상태가 된 직후 `curl http://54.180.237.44/health`에 응답 없음 또는 connection refused |
| **원인 가설** | EC2 인스턴스 OS 부팅 + user-data 스크립트(`apt-get update && apt-get install nginx`) 실행에 소요 시간이 존재. `instance-running` 상태는 하이퍼바이저 레벨 기준이며, OS/앱 기동과 시차가 있음 |
| **검증 방법** | `aws ec2 wait instance-status-ok` 또는 단순 대기(75초) 후 재시도 |
| **검증 결과** | 75초 대기 후 `curl http://54.180.237.44/health` → HTTP 200 / 응답 본문 `OK` 정상 확인 |
| **조치** | EC2 `instance-running` 이후 75초 대기 후 헬스체크 수행 |
| **결과** | 외부 접속 정상 검증 완료 |
| **재발 방지** | 자동화 스크립트에서 `aws ec2 wait instance-status-ok` (2/2 checks passed 기준) 사용 권장. user-data 완료 시그널이 필요하면 CloudWatch Agent 또는 cfn-signal 활용 |

---

## 건 3: IAM 유저 프로파일 설정 — SSO vs 직접 자격증명 혼용

| 항목 | 내용 |
|---|---|
| **증상** | 루트 계정이 SSO 방식으로 인증되어 있고, 새로 생성한 IAM 유저는 직접 Access Key 방식을 사용해야 하는 상황에서 프로파일 충돌 가능성 |
| **원인 가설** | `aws login`(SSO)으로 인증한 기본 프로파일이 `[default]`로 저장되어 있고, IAM 유저의 `--profile b6user`와 경합이 발생할 수 있음 |
| **검증 방법** | `aws sts get-caller-identity --profile b6user` 실행으로 b6user의 ARN 확인 |
| **검증 결과** | `arn:aws:iam::325999880871:user/codyssey-b6-user` 정상 반환 — 프로파일 격리 확인 |
| **조치** | 모든 인프라 명령에 `--profile b6user` 명시적으로 지정 |
| **결과** | 루트/IAM 유저 권한 완전 분리, 최소권한 원칙 적용 |
| **재발 방지** | 실습 환경에서는 항상 `--profile` 플래그를 명시하거나, `AWS_PROFILE=b6user` 환경변수를 셸에 export해서 혼동 방지 |
