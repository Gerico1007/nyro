# Issue: Location Stream Functionality

## 🗺️ Feature Request: Add Location-Based Filtering to Garden Diary

### Description
Add location tracking to the garden diary stream functionality, allowing users to filter and view entries based on where they were when they wrote them.

### Current State
- Garden diary uses Redis streams to store entries
- Each entry has: event, mood (optional), details (optional)
- Can read all entries or by count

### Proposed Enhancement
Add location as a new field to diary entries, enabling location-based filtering and organization.

### User Stories

#### As a user, I want to:
1. **Add location when writing diary entries**
   - When writing a new entry, be prompted for location
   - Location can be free text (e.g., "home", "walk", "park", "coffee shop")
   - Location is optional (can skip if desired)

2. **Filter entries by location**
   - View all entries from a specific location
   - See entries like: "Show me all entries from 'walk'"
   - Get results like: "Found a rare flower (excited) - while walking"

3. **Browse entries by location**
   - See a list of all locations I've written from
   - Choose a location to view its entries

### Technical Implementation Options

#### Option 1: Location as Stream Field (Recommended)
- Add `location` as an optional field in each stream entry
- Filter using Redis stream commands
- Maintain single stream structure

#### Option 2: Location-Based Stream Names
- Create separate streams: `garden.diary.home`, `garden.diary.walk`
- More complex but allows location-specific operations

#### Option 3: Hybrid Approach
- Keep main stream but add location field
- Create location-specific views/commands

### Proposed Menu Changes

#### Current Menu:
```
7) Write in garden diary (STREAM ADD)
8) Read garden diary (STREAM READ)
```

#### Enhanced Menu:
```
7) Write in garden diary (STREAM ADD)
8) Read garden diary (STREAM READ)
9) Show entries by location
10) List all locations
```

### Example Usage

#### Writing with Location:
```
Enter what happened: I saw a beautiful butterfly
Enter mood (optional): happy
Enter location (optional): walk
Enter any extra details (optional): It was orange and black
```

#### Reading by Location:
```
Show me entries from: walk
→ Found a rare flower (excited) - while walking
→ Saw a beautiful butterfly (happy) - while walking
```

### Benefits
- **Better organization**: Group entries by where they happened
- **Memory aid**: Location helps recall context
- **Pattern recognition**: See where you have the most interesting experiences
- **Enhanced storytelling**: Location adds context to your garden diary

### Acceptance Criteria
- [ ] Add location field to stream entries
- [ ] Update menu to prompt for location
- [ ] Add "Show entries by location" menu option
- [ ] Add "List all locations" menu option
- [ ] Update documentation
- [ ] Test with Docker container
- [ ] Ensure backward compatibility with existing entries

### Technical Considerations
- **Backward compatibility**: Existing entries without location should still work
- **Performance**: Location filtering should be efficient
- **User experience**: Location input should be intuitive
- **Data structure**: Consider how to store and query location data efficiently

### Files to Modify
- `scripts/menu.sh` - Add location prompts and new menu options
- `scripts/stream-add.sh` - Handle location field
- `scripts/stream-read.sh` - Add location filtering
- `docs/DOCKER_REDIS_TUTORIAL.md` - Update documentation
- Potentially create new scripts for location-specific operations

### Branch
- **Feature branch**: `feature/location-stream-functionality`
- **Base branch**: `main`

### Labels
- `enhancement`
- `feature`
- `redis-streams`
- `location-tracking` 