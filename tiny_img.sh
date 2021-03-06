#!/bin/bash

M=`/bin/date +%m`
#数据库链接配置
HOSTNAME="127.0.0.1"
PORT="3306"
USERNAME="..."
PASSWORD="..."
DBNAME="..."
#图片读取路径
dir="/home/lzz/imgs/"
#压缩后图片保存位置
tiny="/home/lzz/imgs_tiny/"
#每个月压缩最大次数
COUNT=50

#读取今日新添加的文件
`find $dir -name '*.*g' -ctime -1 | awk -F $dir '{print $NF}' > cname.txt`
#比较今日新添加的文件和昨天压缩的文件，获取没有压缩过的文件
`diff -y --left-column cname.txt tmp.txt | grep  "<" | awk '{print $1}' | grep 'g$' > tmp.txt`
#读取需要压缩的文件
list=`cat /home/lzz/tinyshell/tmp.txt`

#查询可以使用的app key
sql="select app_key,times,month from tinypng"
/phpstudy/mysql/bin/mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${sql}" | while read app_key times month
do
	if [ "$app_key" != "app_key" ]
	then
        #如果时间已经是下一个月那么要更新times=0
	if [ "$month" != "$M" ]
	then
        	sql="update tinypng set times=0,month='$M'"
	        /phpstudy/mysql/bin/mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${sql}"
		times=0
	fi
		#不能超过定义的数
		if [ $times -lt $COUNT ]
		then
			count=$times
			for file_name in $list
			do
				if [ $count -lt $COUNT ]
				then
					file=$dir$file_name
					echo "curl --insecure --user api:$app_key --data-binary @$file -i https://api.tinify.com/shrink"
					url_con=`curl --insecure --retry 3 --connect-timeout 10 -m 300 --user api:$app_key --data-binary @$file -i https://api.tinify.com/shrink`
					echo $url_con
					tmp=${url_con#*\"url\":\"}
					url=${tmp%\"\}\}*}
					`wget -t 3 -T 30 -c --no-check-certificate $url -O $tiny$file_name`
					count=`expr $count + 1`
					sql="update tinypng set times=times+1 where app_key='$app_key'"
					/phpstudy/mysql/bin/mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${sql}"
				else
				break;
				fi
			done
		fi
	fi
done

