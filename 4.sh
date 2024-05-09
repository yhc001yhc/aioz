# 开启cron服务
service cron start

# 添加每日查询余额的cron作业
(crontab -l 2>/dev/null; echo "0 0 * * * /root/3.sh") | crontab -

# 添加每3天自动提取余额的cron作业
(crontab -l 2>/dev/null; echo "0 0 */3 * * /root/1.sh") | crontab -
