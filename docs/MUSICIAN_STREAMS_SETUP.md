# Musician Monitor Portal - Redis Streams Setup Guide

## Overview

This guide walks you through setting up Redis Streams for the Musician Monitor Portal system. The portal uses Redis Streams to deliver real-time instructions to musicians across different instruments.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Musician Monitor Portal                         │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Conductor  │  │   Director   │  │ Sound Engg.  │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│         │                  │                 │               │
│         └──────────────────┼─────────────────┘               │
│                            │                                 │
│         INSTRUCTION DISPATCH API                             │
│         /api/stream/send                                     │
│                            │                                 │
├────────────────────────────┼─────────────────────────────────┤
│                       REDIS STREAMS                          │
│                                                              │
│  musician:guitar1    musician:guitar2    musician:saxophone │
│  musician:vocalist                                           │
│                                                              │
│  (Each with consumer group: monitor_group)                   │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                    MUSICIAN CLIENTS                          │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Guitar 1   │  │   Guitar 2   │  │  Saxophone   │       │
│  │ (Rhythm)     │  │ (Lead)       │  │ (Melody)     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
│  ┌──────────────┐                                            │
│  │   Vocalist   │                                            │
│  │ (Lead Voice) │                                            │
│  └──────────────┘                                            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Stream Configuration

### Musicians & Streams

| Musician | Stream Key | Role | Purpose |
|----------|-----------|------|---------|
| Guitar 1 | `musician:guitar1` | Rhythm | Bass lines, chord progressions |
| Guitar 2 | `musician:guitar2` | Lead | Solo sections, lead lines |
| Saxophone | `musician:saxophone` | Melody | Main melody, saxophone solos |
| Vocalist | `musician:vocalist` | Lead Voice | Lyrics, vocal arrangements |

### Message Format

Each instruction message in a stream contains:

```
{
  "instruction": "The actual instruction text (chords, lyrics, notes, etc.)",
  "timestamp": "ISO 8601 timestamp (e.g., 2024-01-01T12:30:45Z)",
  "priority": "normal | urgent",
  "section": "verse | chorus | bridge | outro | intro" (optional)
}
```

### Consumer Groups

All streams use a single consumer group: **`monitor_group`**

This enables:
- Tracking pending messages
- Load balancing across consumers
- Message acknowledgment tracking

## Setup Instructions

### Step 1: Configure Environment

Ensure your `.env` file contains Upstash credentials:

```bash
# .env (or ~/.env)
KV_REST_API_URL=https://your-instance.upstash.io
KV_REST_API_TOKEN=your_token_here
```

### Step 2: Initialize Streams

Run the initialization script:

```bash
./scripts/init-musician-streams.sh
```

This will:
1. Create 4 musician streams
2. Add an initial "Ready to begin" message to each
3. Create consumer groups for monitoring
4. Verify the setup

Expected output:

```
════════════════════════════════════════════════════════════════
  Musician Monitor Portal - Redis Streams Initialization
════════════════════════════════════════════════════════════════

🔍 Checking Upstash connection...
✅ Connected to Upstash Redis

📡 Initializing musician streams...

→ Setting up Guitar 1 - Rhythm
  → Creating stream: musician:guitar1
  ✅ Stream created successfully
  → Creating consumer group: monitor_group
  ✅ Consumer group created successfully

... (repeats for other musicians)

════════════════════════════════════════════════════════════════
✨ Setup Complete!
```

## Usage

### Sending Instructions

#### Method 1: Using the Send Script

```bash
# Basic instruction
./scripts/send-instruction.sh guitar1 "Play Dm - Dm - G - A"

# With section and priority
./scripts/send-instruction.sh guitar1 "Play Dm - Dm - G - A" verse urgent

# For vocalist with lyrics
./scripts/send-instruction.sh vocalist "Sing verse: La la la..." verse normal

# For saxophone solo
./scripts/send-instruction.sh saxophone "Solo - 4 measures" chorus normal
```

#### Method 2: Direct Redis Command

```bash
# Set a key for your musician client
XADD musician:guitar1 * \
  instruction "Play Dm chord" \
  timestamp "2024-01-01T12:00:00Z" \
  priority "normal" \
  section "verse"
```

#### Method 3: Via REST API (for web portals)

```bash
POST https://your-instance.upstash.io

{
  "command": "XADD musician:guitar1 * instruction 'Play Dm chord' timestamp '2024-01-01T12:00:00Z' priority 'normal' section 'verse'"
}

Headers:
  Authorization: Bearer YOUR_TOKEN
  Content-Type: application/json
```

### Monitoring Streams

Real-time monitoring of all musician streams:

```bash
./scripts/monitor-streams.sh

# Or with custom refresh interval (in seconds)
./scripts/monitor-streams.sh 5
```

This displays:
- Current message count per musician
- Pending messages for each stream
- Last instruction and priority
- Connection status

### Reading Messages

Musicians/clients read their instructions:

```bash
# Read pending messages for a musician
XREADGROUP GROUP monitor_group musician1-client \
  STREAMS musician:guitar1 >

# This returns only unacknowledged messages
```

### Acknowledging Messages

After processing an instruction:

```bash
# Acknowledge the message
XACK musician:guitar1 monitor_group MESSAGE_ID

# This marks it as processed
```

## Musician Client Implementation

### Python Example

```python
import redis
import json
from datetime import datetime

client = redis.Redis(
    host='your-upstash-host',
    port=YOUR_PORT,
    password='your_token',
    decode_responses=True
)

def listen_for_instructions(musician_id):
    """Listen for instructions on musician's stream"""

    stream_key = f"musician:{musician_id}"
    group_name = "monitor_group"
    consumer_name = f"{musician_id}-client"

    while True:
        # Read pending messages
        messages = client.xreadgroup(
            groupname=group_name,
            consumername=consumer_name,
            streams={stream_key: '>'},
            count=1,
            block=1000  # Block for 1 second
        )

        if messages:
            stream, message_list = messages[0]

            for message_id, data in message_list:
                # Process the instruction
                instruction = data.get('instruction', '')
                priority = data.get('priority', 'normal')
                section = data.get('section', '')

                print(f"Priority: {priority}")
                print(f"Instruction: {instruction}")
                if section:
                    print(f"Section: {section}")

                # Execute instruction (play chord, sing lyrics, etc.)
                execute_instruction(instruction)

                # Acknowledge the message
                client.xack(stream_key, group_name, message_id)

def execute_instruction(instruction):
    """Execute the instruction (implement based on musician type)"""
    # For guitar: convert to chord diagrams
    # For vocalist: display lyrics with timing
    # For saxophone: show sheet music
    print(f"Executing: {instruction}")
```

### JavaScript/Node.js Example

```javascript
const redis = require('redis');

const client = redis.createClient({
  url: process.env.KV_REST_API_URL,
  password: process.env.KV_REST_API_TOKEN
});

async function listenForInstructions(musicianId) {
  const streamKey = `musician:${musicianId}`;
  const groupName = 'monitor_group';
  const consumerName = `${musicianId}-client`;

  await client.connect();

  while (true) {
    const messages = await client.xReadGroup(
      groupName,
      consumerName,
      {
        [streamKey]: '>'
      },
      {
        COUNT: 1,
        BLOCK: 1000
      }
    );

    if (messages) {
      for (const [stream, messageList] of messages) {
        for (const message of messageList) {
          const { instruction, priority, section } = message.message;

          console.log(`Priority: ${priority}`);
          console.log(`Instruction: ${instruction}`);
          if (section) console.log(`Section: ${section}`);

          // Execute instruction
          await executeInstruction(instruction);

          // Acknowledge
          await client.xAck(streamKey, groupName, message.id);
        }
      }
    }
  }
}
```

## Advanced Scenarios

### Urgent Instructions Priority

Send urgent instructions that interrupt current playback:

```bash
./scripts/send-instruction.sh guitar1 "STOP - Key change!" chorus urgent
```

Musician clients should:
1. Detect "urgent" priority
2. Immediately stop current instruction
3. Switch to new instruction
4. Sound alert/notification

### Section-Based Organization

Organize instructions by song sections:

```bash
# Verse instructions
./scripts/send-instruction.sh guitar1 "Play Verse Progression" verse normal

# Chorus instructions
./scripts/send-instruction.sh guitar1 "Play Chorus Progression" chorus normal

# Bridge instructions
./scripts/send-instruction.sh guitar1 "Play Bridge Solo" bridge urgent

# Outro instructions
./scripts/send-instruction.sh guitar1 "Final Chord - Hold" outro normal
```

### Broadcasting to All Musicians

Send synchronized instructions to entire band:

```bash
INSTRUCTION="Ready for chorus - in 3...2...1..."

for musician in guitar1 guitar2 saxophone vocalist; do
  ./scripts/send-instruction.sh "$musician" "$INSTRUCTION" chorus normal
done
```

## Monitoring & Debugging

### Check Stream Status

```bash
# Get stream info
INFO musician:guitar1

# Get pending messages
XPENDING musician:guitar1 monitor_group

# Get consumer info
XINFO CONSUMERS musician:guitar1 monitor_group
```

### View Message History

```bash
# Get last 10 messages
XREVRANGE musician:guitar1 + COUNT 10

# Get messages in time range
XRANGE musician:guitar1 1577836800000 1577836900000
```

### Monitor in Real-Time

```bash
./scripts/monitor-streams.sh 1  # Update every 1 second
```

## Troubleshooting

### Issue: "Stream does not exist"

**Solution**: Run initialization script
```bash
./scripts/init-musician-streams.sh
```

### Issue: Messages not appearing in consumer group

**Solution**: Ensure consumer group exists and XREADGROUP uses `>`

### Issue: "NOGROUP" error

**Solution**: Consumer group may need recreation
```bash
XGROUP DESTROY musician:guitar1 monitor_group
XGROUP CREATE musician:guitar1 monitor_group 0
```

### Issue: Connection timeout

**Solution**:
- Verify Upstash credentials in `.env`
- Check network connectivity
- Verify Upstash instance is active

## Best Practices

1. **Always use timestamps**: Include ISO 8601 timestamps with each instruction
2. **Set priority appropriately**: Use "urgent" only for critical changes
3. **Acknowledge messages**: Always acknowledge processed instructions
4. **Monitor pending**: Regularly check for stuck/unacknowledged messages
5. **Clean up consumers**: Remove inactive consumers periodically
6. **Backup stream data**: Consider archiving important instruction sequences
7. **Test failover**: Ensure musician clients can recover from disconnections

## Performance Considerations

- Each stream can handle thousands of messages per minute
- Consumer groups allow parallel processing of messages
- XREADGROUP with BLOCK provides efficient waiting without polling
- Consider using MAXLEN to trim old messages and save space

## Integration with Web Portal

The `/api/stream/send` endpoint (when implemented) should:

1. Validate musician exists
2. Validate instruction format
3. Add timestamp if not provided
4. Send XADD command to Redis
5. Return message ID and status
6. Log for audit trail

## Further Documentation

- [Redis Streams Documentation](https://redis.io/topics/streams-intro)
- [Upstash REST API Guide](https://docs.upstash.com/redis/features/rest)
- [Consumer Groups Tutorial](https://redis.io/topics/streams-intro#consumer-groups)

---

**Last Updated**: 2024-12-04
**Version**: 1.0.0
