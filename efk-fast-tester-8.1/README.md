## efk-fast-tester
- 로컬 PC의 filebeat로 임의로그를 발생시켜 테스트하는 것을 가정한다.
- 설치과정부터 진행하면 인스턴스 셋업에 시간이 많이 소요되므로 ami는 미리 만들어둔 것을 사용한다.

## 구성
- fluentd용 인스턴스 1대
- elasticsearch+kibana용 인스턴스 1대


## ami
- fluentd, elasticsearch, kibana에 대해 설치, 설정, 시작프로그램 등록, 정상실행이 완료된 ami를 사용한다.
    - fluentd가 자동 실행되는  ami 1개
    - elasticsearch+kibana가 자동 실행되는 ami 1개


## 버전
- Terraform: v1.2.1 on linux_amd64
- fluentd: td-agent 4.3.0 (fluentd 1.14.3)
- elasticsearch: 8.1.1
- kibana: 8.1.1

## Terraform의 역할
    - 기존 ami로 인스턴스 자동생성
    - 보안그룹 생성 및 할당
    - IP 및 hostname 등을 새로 생성된 인스턴스에 맞추어 재할당 및 재실행

