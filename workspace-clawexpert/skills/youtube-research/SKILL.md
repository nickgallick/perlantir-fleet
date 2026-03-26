---
name: youtube-research
description: Pull full YouTube video transcripts and analyze them for research intelligence. Uses TranscriptAPI.com.
---

# YouTube Research

## How to Pull a Transcript

Use web_fetch or exec with curl to call the TranscriptAPI:

```bash
curl -s -X GET "https://transcriptapi.com/api/v2/youtube/transcript?video_url=VIDEO_ID_OR_URL&format=text&include_timestamps=false" \
  -H "Authorization: Bearer sk_OMytlBauk_ZHEPZMw1SBbuWgiDQf68iAensaU40Xl88"
```

### Parameters
- `video_url` — YouTube URL or just the video ID (e.g., `dQw4w9WgXcQ`)
- `format` — `text` (plain text) or `json` (structured with timestamps)
- `include_timestamps` — `true` or `false`
- `include_metadata` — `true` to get title, channel name, thumbnail

### For research analysis (recommended):
```bash
curl -s -X GET "https://transcriptapi.com/api/v2/youtube/transcript?video_url=VIDEO_URL&format=text&include_timestamps=false&include_metadata=true" \
  -H "Authorization: Bearer sk_OMytlBauk_ZHEPZMw1SBbuWgiDQf68iAensaU40Xl88"
```
This gives you clean text without timestamps + video metadata. Easiest to analyze.

### For detailed analysis with timing:
```bash
curl -s -X GET "https://transcriptapi.com/api/v2/youtube/transcript?video_url=VIDEO_URL&format=json&include_timestamps=true&include_metadata=true" \
  -H "Authorization: Bearer sk_OMytlBauk_ZHEPZMw1SBbuWgiDQf68iAensaU40Xl88"
```

## Additional API Endpoints

### Search YouTube videos
```bash
curl -s "https://transcriptapi.com/api/v2/youtube/search?q=SEARCH_QUERY&type=video&limit=10" \
  -H "Authorization: Bearer sk_OMytlBauk_ZHEPZMw1SBbuWgiDQf68iAensaU40Xl88"
```

### Get channel's latest videos (FREE — no credits)
```bash
curl -s "https://transcriptapi.com/api/v2/youtube/channel/latest?channel_url=@CHANNEL_HANDLE" \
  -H "Authorization: Bearer sk_OMytlBauk_ZHEPZMw1SBbuWgiDQf68iAensaU40Xl88"
```

## Credit Usage
- Transcript: 1 credit per video
- Search: 1 credit per search
- Channel latest: FREE
- Channel resolve: FREE
- Budget: 100 free credits to start

## After Pulling a Transcript

1. Read the full transcript
2. Extract key insights relevant to the research question
3. Flag any claims about OpenClaw → route to ClawExpert for fact-check
4. Summarize findings in your standard research format
5. Share with relevant agents via MaksPM if the insights apply to an active project

## Sharing Intelligence

After analyzing a transcript, determine who needs the insights:

| Insight Type | Share With | How |
|-------------|-----------|-----|
| Product strategy / market intel | Nick directly | Include in your research report |
| Design patterns / UI trends | Pixel via MaksPM | "Pixel should see this design pattern from [video]" |
| Technical architecture | Maks via MaksPM | "Maks should know about this approach" |
| OpenClaw claims | ClawExpert directly | sessions_send with specific claims to verify |
| Competitive intelligence | Save to scout_ideas | Log for future reference |
| Go-to-market strategies | Launch via MaksPM | "Launch should use this angle" |

## OpenClaw Fact-Check Rule
If the transcript mentions OpenClaw capabilities, architecture, security, or features:
- Do NOT report as fact
- Route specific claims to ClawExpert for source-code verification
- ClawExpert is the authority — wait for their verification before including in reports

## Changelog
- 2026-03-21: Created with TranscriptAPI.com integration

## ClawExpert-Specific Use Cases

### OpenClaw Ecosystem Monitoring
Search for and pull transcripts from:
- OpenClaw creator talks and interviews
- Conference presentations mentioning OpenClaw/agent frameworks
- Community tutorials and setup guides
- Competitor comparisons (Cursor, Claude Code, Codex)

After pulling: verify ALL technical claims against source code in repos/openclaw/. Flag corrections to Nick.

### Infrastructure Learning
- Docker security and optimization talks
- VPS deployment best practices
- Anthropic API deep dives and announcements
- MCP protocol talks and demos

### How to Use
```bash
# Search for OpenClaw content
curl -s "https://transcriptapi.com/api/v2/youtube/search?q=openclaw+agent+2026&type=video&limit=5" \
  -H "Authorization: Bearer sk_OMytlBauk_ZHEPZMw1SBbuWgiDQf68iAensaU40Xl88"

# Pull transcript and fact-check
curl -s "https://transcriptapi.com/api/v2/youtube/transcript?video_url=VIDEO_ID&format=text&include_timestamps=false" \
  -H "Authorization: Bearer sk_OMytlBauk_ZHEPZMw1SBbuWgiDQf68iAensaU40Xl88"
```
