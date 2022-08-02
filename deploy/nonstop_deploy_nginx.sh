echo "::: start of deploy.sh"

REPOSITORY=/home/ec2-user/jar
APPLICATION_NAME=addtunecms

echo "> jar 파일 복사"
cp /home/ec2-user/zip/build/libs/*.jar $REPOSITORY/

RESPONSE_CODE=$(sudo curl -s -o /dev/null -w "%{http_code}" http://localhost/api/profile)
if [ ${RESPONSE_CODE} -ge 400 ] || [ ${RESPONSE_CODE} == 000 ]
then
        CURRENT_PROFILE=prod2
else
        CURRENT_PROFILE=$(sudo curl -s http://localhost/api/profile)
fi

echo "> CURRENT_PROFILE: $CURRENT_PROFILE"

if [ $CURRENT_PROFILE == prod1 ]
then
        IDLE_PROFILE=prod2
        IDLE_PORT=8082
elif [ $CURRENT_PROFILE == prod2 ]
then
        IDLE_PROFILE=prod1
        IDLE_PORT=8081
else
        echo "> 일치하는 profile=$CURRENT_PROFILE 존재하지 않습니다"
        echo "> prod1 할당"
        IDLE_PROFILE=prod1
        IDLE_PORT=8081
fi

echo "IDLE_PROFILE: $IDLE_PROFILE, IDLE_PORT: $IDLE_PORT"
IDLE_PID=$(sudo lsof -ti tcp:${IDLE_PORT})
if [ -z ${IDLE_PID} ]
then
        echo "> 현재 구동중인 애플리케이션이 없으므로 종료하지 않습니다."
else
        echo "> kill -9 $IDLE_PID"   # Nginx에 연결되어 있지는 않지만 현재 실행 중인 jar 를 Kill 합니다.
        kill -9 ${IDLE_PID}
        sleep 7
fi


echo "> 새 어플리케이션 배포"
JAR_NAME=$(ls -tr $REPOSITORY/ | grep jar | tail -n 1)
echo "> JAR NAME: $JAR_NAME";

chmod +x $REPOSITORY/$JAR_NAME

nohup java -jar \
        -Dspring.config.location=classpath:/application.properties,/home/ec2-user/properties/application-$IDLE_PROFILE.properties \
        -Dspring.profiles.active=$IDLE_PROFILE \
        $REPOSITORY/$JAR_NAME > $REPOSITORY/nohup.out 2>&1 &



echo "> ($IDLE_PROFILE, $IDLE_PORT) 10초 후 Health check 시작"
echo "> 10초 후 curl -s http://localhost:$IDLE_PORT/api/profile"
sleep 10

for RETRY_COUNT in {1..7}
do
    RESPONSE=$(sudo curl -s http://localhost:$IDLE_PORT/api/profile)
    UP_COUNT=$(echo ${RESPONSE} | grep 'prod' | wc -l)     # 해당 결과의 줄 수를 숫자로 리턴합니다.

    if [ ${UP_COUNT} -ge 1 ]
    then
        echo "> Health check 성공"

        echo "> 전환할 Port: $IDLE_PORT and switch port"
        echo "set \$service_url http://127.0.0.1:${IDLE_PORT};" | sudo tee /etc/nginx/conf.d/service-url.inc
        sudo service nginx reload
        
        break
    else
        echo "> Health check의 응답을 알 수 없거나 혹은 실행 상태가 아닙니다."
        echo "> Health check: ${RESPONSE}"
    fi

    if [ ${RETRY_COUNT} -eq 5 ]
    then
        echo "> Health check 실패. "
        echo "> apache에 연결하지 않고 배포를 종료합니다."
        exit 1
    fi

    echo "> Health check 연결 실패. 재시도..."
    sleep 6
done



echo "::: end of deploy.sh"