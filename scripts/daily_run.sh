#!/bin/bash
# 每日定时运行 juya-ai-daily（本地 cron 使用）
# 从 GitHub Issues 生成 README.md、BACKUP/、rss.xml，然后 commit & push
# push 后会自动触发 GitHub Actions 的 generate_site.yml 部署到 GitHub Pages

PROJECT_DIR="/data/workspace/Juya新闻助手/juya-ai-daily"
LOG_FILE="${PROJECT_DIR}/cron.log"

cd "${PROJECT_DIR}"

# 激活 Python 环境
export PATH="/root/miniforge3/bin:$PATH"

# 加载 .env 文件
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

# 检查 G_T 是否已设置
if [ -z "$G_T" ] || [ "$G_T" = "your-github-token" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] G_T 未配置，请在 .env 中填写 GitHub Token" >> "${LOG_FILE}"
    exit 1
fi

# 检查 REPO_NAME 是否已设置
REPO_NAME="${REPO_NAME:-alina-lllu/juya-ai-daily}"

echo "========== $(date '+%Y-%m-%d %H:%M:%S') ==========" >> "${LOG_FILE}"

# 1. 先拉取最新代码，避免冲突
echo "  [STEP 1] git pull..." >> "${LOG_FILE}"
git pull origin master >> "${LOG_FILE}" 2>&1

# 2. 安装依赖（首次运行或依赖更新时需要）
pip install -r requirements.txt -q >> "${LOG_FILE}" 2>&1

# 3. 运行 main.py 生成文件
echo "  [STEP 2] python main.py..." >> "${LOG_FILE}"
python main.py "$G_T" "$REPO_NAME" >> "${LOG_FILE}" 2>&1

if [ $? -ne 0 ]; then
    echo "  [ERROR] main.py 运行失败" >> "${LOG_FILE}"
    exit 1
fi

# 4. 提交并推送更改
echo "  [STEP 3] git commit & push..." >> "${LOG_FILE}"
git config user.email "action@github.com" 2>/dev/null
git config user.name "Local Cron" 2>/dev/null
git add -A >> "${LOG_FILE}" 2>&1
git commit -m "update: daily auto-generate $(date '+%Y-%m-%d')" >> "${LOG_FILE}" 2>&1 || echo "  nothing to commit" >> "${LOG_FILE}"
git push origin master >> "${LOG_FILE}" 2>&1 || echo "  [WARN] push failed" >> "${LOG_FILE}"

echo "  [DONE] 完成" >> "${LOG_FILE}"
