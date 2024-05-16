#!/bin/bash

# 定义你的提现脚本路径
SCRIPT_PATH="/root/1.sh"

# 定义日志文件路径
LOG_PATH="/root/withdraw.log"

# 定义Screen名字
SCREEN_NAME="my_withdraw_screen"

# 每2天在后台screen中运行1.sh脚本的Cron作业
# 使用screen -dmS创建一个会话，然后使用screen -S 执行脚本
THREE_DAYS_CRON_JOB="0 0 */2 * * /usr/bin/screen -dmS $SCREEN_NAME $SCRIPT_PATH > $LOG_PATH 2>&1"

# 每天运行3.sh脚本的Cron作业
DAILY_CRON_JOB="0 0 * * * /root/3.sh"

# 使用 grep -v 从 crontab 列表中删除已存在的 1.sh 和 3.sh 相关的cron作业
# 然后添加新的 cron 作业
(crontab -l 2>/dev/null | grep -v -E '1.sh|3.sh'; echo "$DAILY_CRON_JOB"; echo "$THREE_DAYS_CRON_JOB") | crontab -

# 输出当前用户的Crontab，以便检查是否添加成功
crontab -l
