# Redis Streams Systems Guide

This document explains the two complementary Redis Stream systems for musician orchestration.

## Overview

### System 1: Generic Musician Streams (Flexible)
**For:** Custom musician clients and flexible architectures
- 4 separate streams (one per musician)
- Custom message fields
- Direct musician targeting

### System 2: Monitor Portal Stream (Portal App)
**For:** The Next.js Musician Monitor Portal web application
- Single shared stream for all musicians
- Messages filtered by instrument field
- Portal-specific format

---

## System 1: Generic Musician Streams

### Architecture

```
conductor → send-instruction.sh → Redis
                                    ↓
                    ┌───────────────┼───────────────┐
                    ↓               ↓               ↓
              musician:guitar1  musician:guitar2  musician:saxophone  musician:vocalist
              [4 messages]      [4 messages]      [4 messages]        [4 messages]
                    ↓               ↓               ↓               ↓
              Guitar1-Client    Guitar2-Client    Sax-Client      Singer-Client
```

### Streams Created

- `musician:guitar1`
- `musician:guitar2`
- `musician:saxophone`
- `musician:vocalist`

### Consumer Group
- `monitor_group` (one per stream)

### Message Format

```json
{
  "instruction": "Play Dm - Dm - G - A progression",
  "timestamp": "2025-12-05T03:48:10Z",
  "priority": "normal|urgent",
  "section": "verse|chorus|bridge|outro|intro"
}
```

### Usage

#### Initialize Streams
```bash
./scripts/init-musician-streams.sh
```

#### Send Instruction
```bash
./scripts/send-instruction.sh guitar1 "Play Dm chord" verse normal
./scripts/send-instruction.sh guitar1 "STOP - Key change!" chorus urgent
```

#### Monitor All Streams
```bash
./scripts/monitor-streams.sh
```

### Client Implementation

**Python Example:**
```python
import redis

client = redis.Redis(
    host='your-upstash-host',
    port=YOUR_PORT,
    password='your_token'
)

# Read messages
messages = client.xreadgroup(
    groupname='monitor_group',
    consumername='guitar1-client',
    streams={'musician:guitar1': '>'},
    count=1
)

for msg_id, data in messages[0][1]:
    instruction = data[b'instruction'].decode()
    priority = data[b'priority'].decode()

    # Process instruction...

    # Acknowledge
    client.xack('musician:guitar1', 'monitor_group', msg_id)
```

**JavaScript/Node.js Example:**
```javascript
const redis = require('redis');

const client = redis.createClient({
  url: process.env.KV_REST_API_URL,
  password: process.env.KV_REST_API_TOKEN
});

await client.connect();

const messages = await client.xReadGroup(
  'monitor_group',
  'guitar1-client',
  { 'musician:guitar1': '>' },
  { COUNT: 1 }
);

for (const [stream, msg] of messages) {
  const { instruction, priority, section } = msg.message;

  // Process instruction...

  // Acknowledge
  await client.xAck('musician:guitar1', 'monitor_group', msg.id);
}
```

### Advantages

✓ Direct stream per musician (no filtering needed)
✓ Flexible message fields
✓ Custom actions and metadata
✓ Works with any Redis client
✓ Simple consumer group setup per stream

### Use Cases

- Custom musician client applications
- Mobile apps with specific requirements
- Backend orchestration systems
- Advanced message routing

---

## System 2: Monitor Portal Stream

### Architecture

```
conductor → send-monitor-instruction.sh → gmusic:score stream
                                                      ↓
                    ┌─────────────────────────────────┼──────────────────────┐
                    ↓                                  ↓                      ↓
            Guitar1-Filter            Guitar2-Filter            Sax-Filter
            (instrument=guitar_1)     (instrument=guitar_2)    (instrument=saxophone)
                    ↓                                  ↓                      ↓
            Monitor Portal WebApp
                    ↓
    ┌───────────────┼───────────────┬────────────────┐
    ↓               ↓               ↓                ↓
Guitar1 Display  Guitar2 Display  Sax Display  Vocalist Display
```

### Stream Configuration

- **Stream Name:** `gmusic:score`
- **Consumer Group:** `gmusic:ensemble:sessionA`

### Message Format

```json
{
  "instrument": "guitar_1|guitar_2|saxophone|vocalist",
  "action": "show_chords|show_lyrics|highlight_section|...",
  "data": "C Am F G",
  "transpose": 0,
  "bar": "32",
  "timestamp": "2025-12-05T04:02:17Z"
}
```

### Field Descriptions

| Field | Type | Required | Example | Notes |
|-------|------|----------|---------|-------|
| `instrument` | string | Yes | `guitar_1` | Must match: `guitar_1`, `guitar_2`, `saxophone`, `vocalist` |
| `action` | string | Yes | `show_chords` | Specifies what to display/do |
| `data` | string | Yes | `C Am F G` | Chord progressions, lyrics, notes, etc. |
| `transpose` | number | No | `2` | Capo/transposition value for guitarists |
| `bar` | string | No | `32` | Bar/measure number for reference |
| `timestamp` | string | Auto | (ISO 8601) | Set automatically by server |

### Usage

#### Initialize Portal Stream
```bash
./scripts/init-monitor-portal-stream.sh
```

#### Send Instructions to Portal

**Basic:** Send chords
```bash
./scripts/send-monitor-instruction.sh guitar_1 show_chords "C Am F G"
```

**With Transposition:** Guitar 2 plays same chords in different key
```bash
./scripts/send-monitor-instruction.sh guitar_2 show_chords "G Em D A" 2
```

**With Bar Number:** Reference the measure
```bash
./scripts/send-monitor-instruction.sh guitar_1 show_chords "Dm" 32
```

**For Vocalist:** Show lyrics
```bash
./scripts/send-monitor-instruction.sh vocalist show_lyrics "Verse 1: La la la..."
```

**For Saxophone:** Show melody
```bash
./scripts/send-monitor-instruction.sh saxophone show_melody "Counter-melody in E minor"
```

### Portal API Integration

The Monitor Portal provides two endpoints:

#### Send Instruction (POST `/api/stream/send`)

```bash
curl -X POST http://localhost:3000/api/stream/send \
  -H "Content-Type: application/json" \
  -d '{
    "instrument": "guitar_1",
    "action": "show_chords",
    "data": "C Am F G",
    "transpose": 0,
    "bar": "32"
  }'
```

#### Read Instructions (POST `/api/stream/read`)

```bash
curl -X POST http://localhost:3000/api/stream/read \
  -H "Content-Type: application/json" \
  -d '{
    "musicianId": "guitar_1",
    "count": 10
  }'
```

### Portal Client Behavior

Musicians open the portal on their device and:

1. Select their instrument (`guitar_1`, `guitar_2`, `saxophone`, `vocalist`)
2. Portal polls the API endpoint continuously
3. Messages for their instrument are displayed
4. Other instruments' messages are filtered out by the portal

### Advantages

✓ Single stream reduces Redis memory
✓ Web-based UI out of the box
✓ Transposition auto-calculated for guitarists
✓ Mobile-friendly interface
✓ Consumer groups handle message acknowledgment
✓ Built-in fault tolerance

### Use Cases

- Live performance monitoring
- Rehearsal coordination
- Remote musician guidance
- Teaching/conducting scenarios
- Music stand display system

---

## Comparison Matrix

| Feature | Musician Streams | Monitor Portal |
|---------|-----------------|----------------|
| **Stream Structure** | 4 separate streams | 1 shared stream |
| **Message Filtering** | Consumer targets stream | App filters by instrument |
| **Setup Complexity** | Medium | Low |
| **Memory Usage** | Higher | Lower |
| **Web UI** | Requires custom build | Built-in Next.js app |
| **Client Flexibility** | Very flexible | Portal-dependent |
| **Consumer Groups** | Per stream | Single group |
| **Transposition Support** | Manual in message | Auto-calculated |
| **Recommended For** | Custom apps | Portal deployment |

---

## Choosing the Right System

### Use Musician Streams (System 1) If:
- Building custom musician client applications
- Need maximum flexibility in message format
- Each musician has specialized hardware/software
- Want to avoid filtering logic in clients
- Building a distributed system

### Use Monitor Portal (System 2) If:
- Running the Next.js Monitor Portal
- Musicians use tablets/browsers as display
- Want simple web-based interface
- Need automatic transposition handling
- Want built-in mobile optimization

### Use Both If:
- Running the portal AND custom clients
- Some musicians use the portal, others use custom apps
- Need redundancy or failover capability
- Different instruments have different needs

---

## Monitoring & Debugging

### Check Stream Status (Musician Streams)

```bash
# See all messages in a stream
redis-cli XRANGE musician:guitar1 - +

# Get stream length
redis-cli XLEN musician:guitar1

# Check consumer group info
redis-cli XINFO GROUPS musician:guitar1
```

### Check Stream Status (Portal Stream)

```bash
# See all messages
redis-cli XRANGE gmusic:score - +

# Get stream length
redis-cli XLEN gmusic:score

# Check consumer group info
redis-cli XINFO GROUPS gmusic:score

# Check pending messages
redis-cli XPENDING gmusic:score gmusic:ensemble:sessionA
```

---

## Performance Considerations

### Message Volume
- **Musician Streams:** 4 streams × N messages = 4N total
- **Monitor Portal:** N messages total (shared)

### Consumer Group Overhead
- **Musician Streams:** 4 groups (one per stream)
- **Monitor Portal:** 1 group (shared)

### Filtering Cost
- **Musician Streams:** 0 (direct stream access)
- **Monitor Portal:** Low (simple field match in app)

---

## Best Practices

1. **Timestamping:** Always include ISO 8601 timestamps
2. **Data Format:** Keep data compact and clear
3. **Monitoring:** Monitor pending message counts
4. **Acknowledgment:** Always acknowledge processed messages
5. **Error Handling:** Implement retry logic in clients
6. **Clean Up:** Archive/delete old messages periodically

---

## Migration Path

If starting with Musician Streams and later need the Portal:

1. Deploy Monitor Portal pointing to a new `gmusic:score` stream
2. Keep Musician Streams running for legacy clients
3. Implement dual-write in conductor: send to both systems
4. Gradually migrate musicians to Portal
5. Once all on Portal, decommission Musician Streams

---

## Support

For issues or questions:

- **Musician Streams:** Check `docs/MUSICIAN_STREAMS_SETUP.md`
- **Monitor Portal:** Check Monitor Portal README.md
- **Both Systems:** See troubleshooting sections in respective docs

---

**Last Updated:** 2025-12-05
**Version:** 1.0.0
