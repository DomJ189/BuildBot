@echo off
IF "%1"=="--version" (
  echo 12.4.6
) ELSE IF "%1"=="projects:list" (
  echo {"result":{"projects":[{"projectId":"buildbot-46180","displayName":"BuildBot"}]}}
) ELSE (
  "C:\Users\domin\Firebase\firebase.exe" %*
) q