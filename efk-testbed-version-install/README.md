## efk-testbed-version-install
- 로컬 PC의 filebeat로 임의로그를 발생시켜 테스트하는 것을 가정한다.
- EFK스택을 설치부터 실행까지한다. 새 버전을 적용 및 테스트하는 데 활용한다.
- efk_config 내 설정 파일들은 elastic 8.1~8.4 까지 무리 없이 적용가능하다.

## 구성
- fluentd용 인스턴스 1대
- elasticsearch+kibana용 인스턴스 1대

## ami
- basic ubuntu 22
- fluentd, elasticsearch, kibana에 대해 설치, 설정, 시작프로그램 등록을 모두 실행

## 버전
- Terraform: v1.2.1 on linux_amd64
- fluentd, elasticsearch, kibana: config.tfvars 파일로 정의

## Terraform의 역할
    - 보안그룹 자동 생성 및 할당
    - 새로 생성된 인스턴스의 IP 및 hostname 등에 맞게 EFK 스택 connection이 수립되도록 한다.
