# Redis Streams in Nyro

Redis Streams provide a log-like data structure that enables you to record and track time-series data, events, or any sequential information in your Nyro implementation.

## Quick Start

### Adding Entries to a Stream
Use the `stream-add.sh` script to add entries to your stream:

```bash
./scripts/stream-add.sh <stream-name> <field1> <value1> [field2 value2 ...]
```

Example:
```bash
./scripts/stream-add.sh sensor.data temperature 25.5 humidity 80
```

### Reading from a Stream
Use the `stream-read.sh` script to read entries from your stream:

```bash
./scripts/stream-read.sh <stream-name> [count]
```

Example:
```bash
./scripts/stream-read.sh sensor.data 10  # reads last 10 entries
```

## Use Cases

1. **Time-Series Data**
   - Sensor readings
   - System metrics
   - User activity logs

2. **Event Sourcing**
   - User interactions
   - System state changes
   - Audit trails

3. **Memory Garden Events**
   - Growth tracking
   - Environmental changes
   - Garden maintenance records

## Stream Structure

Each entry in a Redis Stream consists of:
- A unique ID (automatically generated timestamp)
- One or more field-value pairs

Example stream entry:
```
1750216159096-0:
  sensor_temp: "25.5"
  humidity: "80"
```

## Best Practices

1. **Stream Naming**
   - Use descriptive names (e.g., `sensor.data`, `user.events`)
   - Add prefixes for categorization
   - Use dots (.) for hierarchical names

2. **Field Names**
   - Keep them consistent across entries
   - Use descriptive names
   - Consider using prefixes for related fields

3. **Data Organization**
   - Group related data in the same stream
   - Use multiple fields rather than multiple streams
   - Consider time-based partitioning for large datasets

## Advanced Usage

### Music Notation System
The Nyro Music Notation System uses Redis Streams to store and manage musical notation data. Use the specialized menu:
```bash
./scripts/music-menu.sh
```

Features:
- Store ABC notation or MusicXML parts
- Organize multiple parts of a composition
- Track changes and versions
- Search by part ID

Example music notation entry:
```bash
./scripts/stream-add.sh notation:stream \
  part_id "violin1" \
  format "abc" \
  content "X:1\nT:Example\nM:4/4\nK:C\nCDEF|GABc|" \
  timestamp "$(date -u +%FT%TZ)"
```

### Pattern Examples

1. **Sensor Readings**
```bash
./scripts/stream-add.sh garden.sensors \
  temp_celsius 23.5 \
  humidity_pct 65 \
  light_level 800 \
  timestamp "$(date -u +%FT%TZ)"
```

2. **Event Logging**
```bash
./scripts/stream-add.sh system.events \
  event_type "user_login" \
  user_id "12345" \
  ip_address "192.168.1.1" \
  timestamp "$(date -u +%FT%TZ)"
```

3. **Garden Memory**
```bash
./scripts/stream-add.sh garden.memory \
  plant_id "tomato_1" \
  action "watering" \
  amount_ml 250 \
  notes "Added fertilizer" \
  timestamp "$(date -u +%FT%TZ)"
```
