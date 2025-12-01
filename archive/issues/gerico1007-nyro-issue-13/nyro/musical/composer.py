"""
Session Composer Module
🎸 JamAI: Musical composition for development sessions

Provides advanced composition features for:
- Session-specific melody generation
- Team harmony orchestration  
- Pattern-based musical motifs
- ABC notation composition
"""

from typing import Dict, List, Optional, Any
from .ledger import MusicalLedger, MusicalEntry
import math


class SessionComposer:
    """Advanced session composition and musical generation."""
    
    def __init__(self, musical_ledger: MusicalLedger):
        """Initialize composer with musical ledger."""
        self.ledger = musical_ledger
        
        # Redis operation to musical element mapping
        self.operation_mapping = {
            'SET': {
                'note_pattern': 'C2E2G2c2',  # Foundation chord
                'dynamic': 'mf',
                'tempo_modifier': 1.0,
                'harmonic_role': 'bass'
            },
            'GET': {
                'note_pattern': 'G4A4B4c4',  # Ascending query
                'dynamic': 'mp',
                'tempo_modifier': 1.2,
                'harmonic_role': 'melody'
            },
            'XADD': {
                'note_pattern': 'C4G4C4G4',  # Rhythmic pattern
                'dynamic': 'f',
                'tempo_modifier': 0.8,
                'harmonic_role': 'rhythm'
            },
            'DEL': {
                'note_pattern': 'z2',  # Rest/silence
                'dynamic': 'pp',
                'tempo_modifier': 1.0,
                'harmonic_role': 'rest'
            },
            'XRANGE': {
                'note_pattern': 'E4F4G4A4B4c4',  # Flowing sequence
                'dynamic': 'mp',
                'tempo_modifier': 1.1,
                'harmonic_role': 'melody'
            }
        }
        
        # Key modulation based on database profiles
        self.database_keys = {
            'default': 'C',
            'garden': 'G',
            'dev': 'D',
            'test': 'F',
            'prod': 'Bb'
        }
    
    def compose_team_harmony(self, session_id: str) -> str:
        """Compose harmony based on team activities."""
        entries = self.ledger.get_session_entries(session_id)
        
        # Group by team member
        team_activities = {}
        for entry in entries:
            if entry.team_member:
                if entry.team_member not in team_activities:
                    team_activities[entry.team_member] = []
                team_activities[entry.team_member].append(entry)
        
        # Generate harmony for each voice
        harmony_parts = []
        
        for member, activities in team_activities.items():
            part = self._generate_member_voice(member, activities)
            harmony_parts.append(f"% {member} Voice\\n{part}")
        
        return "\\n\\n".join(harmony_parts)
    
    def _generate_member_voice(self, member: str, activities: List[MusicalEntry]) -> str:
        """Generate musical voice for team member."""
        # Simple pattern generation based on member type
        patterns = {
            "♠️": "G2B2 d2B2",  # Structured patterns
            "🌿": "F2A2 c2A2",  # Flowing patterns
            "🎸": "C2E2 G2E2",  # Harmonic patterns  
            "🧵": "D2F#2 A2F#2" # Technical patterns
        }
        
        base_pattern = patterns.get(member, "C2E2 G2C2")
        
        # Extend pattern based on activity count
        activity_count = len(activities)
        measures = []
        
        for i in range(min(activity_count, 4)):
            measures.append(base_pattern)
            
        return f"|: {' | '.join(measures)} :|"
    
    def generate_session_theme(self, session_id: str) -> str:
        """Generate main theme for session."""
        melody = self.ledger.session_melodies.get(session_id)
        if not melody:
            return "C4 E4 G4 c4"  # Default theme
            
        # Extract key signature and build theme
        key = melody.key_signature
        
        # Simple theme generation based on key
        themes = {
            "C": "C4 E4 G4 c4",
            "G": "G4 B4 d4 g4", 
            "F": "F4 A4 c4 f4",
            "D": "D4 F#4 A4 d4"
        }
        
        return themes.get(key, "C4 E4 G4 c4")
    
    def export_full_composition(self, session_id: str) -> str:
        """Export complete ABC composition for session."""
        melody = self.ledger.session_melodies.get(session_id)
        if not melody:
            return ""
            
        composition = f"""X:1
T:{melody.title}
C:♠️🌿🎸🧵 G.Music Assembly  
M:{melody.time_signature}
L:1/8
K:{melody.key_signature}
Q:{melody.tempo}

% Main Session Theme
{self.generate_session_theme(session_id)}

% Team Harmony
{self.compose_team_harmony(session_id)}

% Session Progression
{melody.abc_notation}
"""
        
        return composition
    
    def compose_redis_operation(self, operation: str, data_size: int = 0, database: str = 'default') -> str:
        """Compose ABC notation for a Redis operation."""
        mapping = self.operation_mapping.get(operation.upper(), self.operation_mapping['SET'])
        
        # Base pattern
        pattern = mapping['note_pattern']
        
        # Modify pattern based on data size
        if data_size > 1000:  # Large data = extended chords
            pattern = self._extend_chord(pattern)
        elif data_size > 100:  # Medium data = add harmonies
            pattern = self._add_harmony(pattern)
            
        # Add dynamic marking
        dynamic = mapping['dynamic']
        if data_size > 500:
            dynamic = 'f'  # Forte for large data
        elif data_size < 10:
            dynamic = 'pp'  # Pianissimo for small data
            
        return f"!{dynamic}!{pattern}"
    
    def _extend_chord(self, pattern: str) -> str:
        """Extend chord for large data operations."""
        # Add 7th and 9th extensions
        if 'C2E2G2c2' in pattern:
            return pattern.replace('c2', 'c2B2d2')
        return pattern + ' B2d2'
    
    def _add_harmony(self, pattern: str) -> str:
        """Add harmony notes for medium data."""
        # Add parallel thirds
        return pattern + ' [CEG]2'
    
    def calculate_dynamic_tempo(self, operations_count: int, time_window: float = 60.0) -> int:
        """Calculate tempo based on operation frequency."""
        base_tempo = 120
        ops_per_minute = operations_count / (time_window / 60.0)
        
        # Scale tempo with operation frequency
        if ops_per_minute > 100:  # Very fast operations
            return min(180, base_tempo + int(ops_per_minute * 0.5))
        elif ops_per_minute < 5:  # Slow operations
            return max(60, base_tempo - 30)
        else:
            return base_tempo
    
    def modulate_key(self, current_key: str, database: str) -> str:
        """Modulate key based on database change."""
        target_key = self.database_keys.get(database, 'C')
        if current_key != target_key:
            # Update current session key
            if self.ledger.current_session_id in self.ledger.session_melodies:
                self.ledger.session_melodies[self.ledger.current_session_id].key_signature = target_key
                self.ledger._save_ledger()
        return target_key
    
    def compose_operation_sequence(self, operations: List[Dict[str, Any]]) -> str:
        """Compose a sequence of operations into musical phrases."""
        phrases = []
        current_key = 'C'
        operation_count = len(operations)
        
        # Calculate dynamic tempo
        tempo = self.calculate_dynamic_tempo(operation_count)
        
        for i, op in enumerate(operations):
            operation = op.get('operation', 'SET')
            data_size = op.get('data_size', 0)
            database = op.get('database', 'default')
            
            # Handle key modulation
            new_key = self.modulate_key(current_key, database)
            if new_key != current_key:
                phrases.append(f"K:{new_key}")  # Key change notation
                current_key = new_key
            
            # Compose operation
            phrase = self.compose_redis_operation(operation, data_size, database)
            phrases.append(phrase)
            
            # Add measure breaks every 4 operations
            if (i + 1) % 4 == 0:
                phrases.append('|')
        
        # Update session tempo
        if self.ledger.current_session_id in self.ledger.session_melodies:
            self.ledger.session_melodies[self.ledger.current_session_id].tempo = tempo
            self.ledger._save_ledger()
        
        return ' '.join(phrases)
    
    def generate_session_story(self, session_id: str) -> str:
        """Generate musical story of the entire session."""
        entries = self.ledger.get_session_entries(session_id)
        melody = self.ledger.session_melodies.get(session_id)
        
        if not melody:
            return ""
            
        story = f"""X:1
T:Redis Session Story - {melody.title}
C:♠️🌿🎸🧵 G.Music Assembly
M:{melody.time_signature}
L:1/8
K:{melody.key_signature}
Q:{melody.tempo}

% Session opens with foundation
A:| C2E2G2c2 | z2 !mp!G4A4B4c4 |

% Operation sequences from session
B:| {melody.abc_notation} |

% Team harmony finale
C:| [CEG]2[DFA]2[EGB]2[FAc]2 | [CEGc]4 z4 |]
"""
        
        return story