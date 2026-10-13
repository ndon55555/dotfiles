---
name: zed
description: Open the current working directory in Zed
disable-model-invocation: true
allowed-tools: Bash(zed:*)
---

!`zed "$PWD" && echo "Opened $PWD in Zed"`

Reply with only the line above. Do nothing else.
