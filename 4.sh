#!/bin/bash

# 定义你的提现脚本路径
SCRIPT_PATH="/root/1.sh"

# 定义日志文件路径
LOG_PATH="/root/withdraw.log"

# 新的Cron作业
CRON_JOB="0 0 */5 * * nohup $SCRIPT_PATH > $LOG_PATH 2>&1"

# 将新的Cron作业添加到Crontab中，不影响现有的Cron作业
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# 输出当前用户的Crontab，以便检查是否添加成功
crontab -l
