#!/bin/bash
# Publishes a diagnostic snapshot to branch "ci-logs" via the contents API,
# so the log can be read even when the runner dies and Actions logs are unavailable.
set +e
SNAP=/tmp/snap.txt
{
  echo "== $(date -u) run=$GITHUB_RUN_ID sha=$GITHUB_SHA"
  free -m | sed -n 1,3p
  df -h / | tail -1
  echo "== oom/kill messages"
  sudo dmesg 2>/dev/null | grep -iE "out of memory|killed process|oom-kill" | tail -5
  echo "== last 250 lines of build.log"
  tail -n 250 "$GITHUB_WORKSPACE/build.log" 2>/dev/null
  echo "== out/error.log"
  tail -n 100 "$GITHUB_WORKSPACE/twrp/out/error.log" 2>/dev/null
} > "$SNAP" 2>&1
API="https://api.github.com/repos/$GITHUB_REPOSITORY/contents/ci-logs/run-$GITHUB_RUN_ID.txt"
SHA=$(curl -s -H "Authorization: Bearer $GH_TOKEN" "$API?ref=ci-logs" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha',''))")
base64 -w0 "$SNAP" > /tmp/snap.b64
python3 - "$SHA" > /tmp/body.json <<'PY'
import sys,json
b={"message":"ci log","content":open('/tmp/snap.b64').read(),"branch":"ci-logs"}
if sys.argv[1]: b["sha"]=sys.argv[1]
print(json.dumps(b))
PY
curl -s -o /dev/null -X PUT -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" -d @/tmp/body.json "$API"
