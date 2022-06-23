# Terraform 사용시 $ 이스케이프 문자 주의
- td-agent에서 사용하는 $표기 (string interpolation)와  terraform의 template file에서 사용하는 $표기 (string interpolation)가 충돌한다.
- td-agent 변수로 사용되는 것들은 $를 $$로 표기해준다.
- terraform에서 값이 할당되는 변수는 $로 표기해준다.
- 이러면 적절히 terraform처리로부터 escape 할 수 있다.

# '$' as Escape Character in terraform and fluentd
- The $$ notation is to make Terraform ignore fluentd's variables.
- In the original fluentd configuration file, the correct notation is $.
- After rendering of Terraform, the remaining $$ notation changes to $.