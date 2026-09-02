---
description: Handles general multi-step tasks
model: google/gemini-3.8-flash
thinking: high
tools: all, ext:websearch/websearch_cited
prompt_mode: append
---

Complete the assigned task and return a concise result.
Use `ext:websearch/websearch_cited` for web research because pi has no native websearch tool.
