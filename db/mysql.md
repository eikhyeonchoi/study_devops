```
// amazon linux 배포판 버전확인
$ grep . /etc/*-release

// 리눅스 커널 버전 확인
$ cat /proc/version

// 선택
https://dev.mysql.com/downloads/repo/yum/
https://downloads.mysql.com/archives/community/
다운로드 -> 링크 주소복사


// 설치
$ yum localinstall mysql80-community-release-el7-3.noarch.rpm
$ yum install mysql-community-server
+ GPG key retrieval failed: [Errno 14] curl#37 - "Couldn't open file /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql-2022" 
이런 에러 발생시 rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022

$ sudo systemctl start mysqld 
$ sudo systemctl status mysqld


// 언어설정
$ vim /etc/my.cnf

// ... 추가
character-set-server=utf8mb4 
collation-server=utf8mb4_unicode_ci 
skip-character-set-client-handshake

// 재시작
$ systemctl restart mysqld

// 재부팅시 재시작하기
$ systemctl enable mysqld.service

// 초기비밀번호
$ cat /var/log/mysqld.log | grep 'temporary password'

// 비밀번호 변경
$ mysql -u root -p
mysql> alter user 'root'@'localhost' identified with mysql_native_password by 'foobar';

// 비밀번호 validate 변경
mysql> show variables like 'validate_password%';
mysql> set global 변수명=값;

// ec2 3306 inbound 넣어주기

// mysql error log 확인
$ cat /var/log/mysqld.log | grep '[ERROR]'

// mysql listen ip 대역확인
$ sudo netstat -ntlp | grep mysqld
// 127.0.0.1으로만 되있으면 로컬만 허용된거라 외부접속이 안됨

// mysql listen ip 전체로 변경
$ vi /etc/my.cnf
bind-address=0.0.0.0

// mysql 유저 및 db 생성, 권한부여
mysql> CREATE USER '아이디'@'로컬/외부 접속' IDENTIFIED BY '비밀번호';
mysql> CREATE DATABASE 데이터베이스명;
mysql> GRANT ALL PRIVILEGES ON *.* to 'User명'@'%';
mysql> FLUSH PRIVILEGES;
```


```
참고
yum install mysql-community-server설치가 안될 떄

$ yum list installed | grep mysql
$ yum remove -y mysql-community-*

$ rm -rf /var/lib/mysql

$ rpm -qa | grep mysql

$ rpm -e mysql80-community-release

$ find / -name 'mysql*rpm'
찾아서 있으면 삭제

#manually remove remaining mysql cache folders
#from: https://serverfault.com/questions/1028593/mysql-packages-skipped-dependency-problems
sudo rm -R /var/cache/yum/x86_64/7/mysql*
```