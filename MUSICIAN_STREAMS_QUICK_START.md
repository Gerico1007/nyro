# 🎼 Musician Monitor Portal - Quick Start Guide

## What's New?

Your musician monitor portal now has a complete Redis Streams infrastructure for real-time instruction delivery to musicians.

## Quick Commands

### 1️⃣ First Time Setup

```bash
# Initialize all musician streams
./scripts/init-musician-streams.sh
```

✅ Creates 4 musician streams with consumer groups
✅ Automatically verifies setup
✅ Ready to receive instructions

### 2️⃣ Send Instructions

```bash
# Basic instruction
./scripts/send-instruction.sh guitar1 "Play Dm chord"

# With song section
./scripts/send-instruction.sh guitar1 "Play Dm - Dm - G - A" verse

# Urgent instruction
./scripts/send-instruction.sh guitar1 "KEY CHANGE!" chorus urgent

# For vocalist
./scripts/send-instruction.sh vocalist "Sing verse: La la la..." verse normal
```

### 3️⃣ Monitor All Musicians

```bash
# Real-time dashboard
./scripts/monitor-streams.sh

# Refresh every 2 seconds
./scripts/monitor-streams.sh 2
```

Displays:
- Total messages per musician
- Pending instructions
- Last instruction sent
- Priority levels

## Musicians & Their Streams

| Role | Stream Key | Instruments |
|------|-----------|-------------|
| 🎸 Rhythm Guitar | `musician:guitar1` | Bass lines, chords |
| 🎸 Lead Guitar | `musician:guitar2` | Solos, fills |
| 🎷 Saxophone | `musician:saxophone` | Melody, solos |
| 🎤 Vocalist | `musician:vocalist` | Lyrics, harmony |

## Message Types

### Normal Instruction
```bash
./scripts/send-instruction.sh guitar1 "Play Verse Progression"
```

### Urgent Instruction (interrupts current)
```bash
./scripts/send-instruction.sh guitar1 "STOP - Key change!" chorus urgent
```

### Section-Based Instruction
```bash
./scripts/send-instruction.sh saxophone "Solo section" chorus normal
```

## Real-World Scenario

### Setup a Performance

```bash
# 1. Initialize (one time)
./scripts/init-musician-streams.sh

# 2. Send verse instructions to all
./scripts/send-instruction.sh guitar1 "Verse progression: Em - Am - D - G" verse normal
./scripts/send-instruction.sh guitar2 "Rhythm comp on verse" verse normal
./scripts/send-instruction.sh saxophone "Hold - enter on chorus" verse normal
./scripts/send-instruction.sh vocalist "Sing verse 1" verse normal

# 3. Monitor real-time
./scripts/monitor-streams.sh

# 4. When ready for chorus, send updates
./scripts/send-instruction.sh guitar1 "Chorus progression - power chords" chorus normal
./scripts/send-instruction.sh guitar2 "Chorus solo - 4 measures" chorus normal
./scripts/send-instruction.sh saxophone "Enter with melody" chorus normal
./scripts/send-instruction.sh vocalist "Sing chorus with harmony" chorus normal
```

## File Locations

### Scripts
```
scripts/
├── init-musician-streams.sh    # Initialize streams
├── send-instruction.sh         # Send instructions
└── monitor-streams.sh          # Monitor dashboard
```

### Documentation
```
docs/
└── MUSICIAN_STREAMS_SETUP.md   # Complete guide
    ├── Architecture
    ├── Python/JavaScript examples
    ├── Advanced scenarios
    └── Troubleshooting
```

## Environment Setup

Your `.env` file needs:

```bash
KV_REST_API_URL=https://your-instance.upstash.io
KV_REST_API_TOKEN=your_token_here
```

## Example: Band Coordination

```bash
# Sync all musicians at start
for musician in guitar1 guitar2 saxophone vocalist; do
  ./scripts/send-instruction.sh "$musician" "Ready? In 3...2...1..." intro normal
done

# Monitor for readiness
./scripts/monitor-streams.sh

# Send verse start signal
for musician in guitar1 guitar2 saxophone vocalist; do
  ./scripts/send-instruction.sh "$musician" "Verse - NOW!" verse normal
done
```

## Musician Client Examples

### Python Musician Client

```python
import redis

# Connect to your Redis instance
client = redis.Redis(host='...', password='...')

musician_id = 'guitar1'
stream_key = f'musician:{musician_id}'
group_name = 'monitor_group'
consumer = f'{musician_id}-client'

# Listen for instructions
while True:
    messages = client.xreadgroup(
        groupname=group_name,
        consumername=consumer,
        streams={stream_key: '>'}
    )

    if messages:
        stream, msg_list = messages[0]
        for msg_id, data in msg_list:
            instruction = data.get('instruction', '')
            priority = data.get('priority', 'normal')
            section = data.get('section', '')

            # Execute instruction
            print(f"Playing: {instruction} ({priority})")

            # Acknowledge
            client.xack(stream_key, group_name, msg_id)
```

### JavaScript Musician Client

```javascript
const redis = require('redis');

const client = redis.createClient({
  url: process.env.KV_REST_API_URL,
  password: process.env.KV_REST_API_TOKEN
});

async function listenForInstructions() {
  await client.connect();

  const streamKey = 'musician:guitar1';
  const groupName = 'monitor_group';
  const consumer = 'guitar1-client';

  while (true) {
    const messages = await client.xReadGroup(
      groupName,
      consumer,
      { [streamKey]: '>' },
      { BLOCK: 1000 }
    );

    if (messages) {
      for (const [stream, msgList] of messages) {
        for (const msg of msgList) {
          console.log(`Playing: ${msg.message.instruction}`);
          await client.xAck(streamKey, groupName, msg.id);
        }
      }
    }
  }
}
```

## Troubleshooting

### Streams not appearing?
```bash
# Re-initialize
./scripts/init-musician-streams.sh
```

### Check stream status
```bash
# View stream info
redis-cli XINFO STREAM musician:guitar1

# Or via Upstash console
XLEN musician:guitar1
```

### Messages stuck?
```bash
# Check pending messages
XPENDING musician:guitar1 monitor_group
```

## Next Steps

1. ✅ Run initialization: `./scripts/init-musician-streams.sh`
2. ✅ Send test instruction: `./scripts/send-instruction.sh guitar1 "Test"`
3. ✅ Open monitor: `./scripts/monitor-streams.sh`
4. 📖 Read full guide: `docs/MUSICIAN_STREAMS_SETUP.md`
5. 🚀 Integrate into your app

## Support

For detailed information, see:
- `docs/MUSICIAN_STREAMS_SETUP.md` - Complete documentation
- `scripts/*.sh` - Script source code
- Redis Streams: https://redis.io/topics/streams-intro

---

**Version**: 1.0.0
**Created**: 2024-12-04
**Related Issue**: #24 - Musician Monitor Portal - Redis Streams Integration
