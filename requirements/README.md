# Requirements Documentation

This document explains the different requirements files and their purposes in the Nyro project.

## Structure

```
requirements/
├── cli-requirements.txt    # System requirements for CLI tools
├── system-requirements.txt # Detailed system dependencies
├── base.txt               # Core Python package dependencies
├── dev.txt               # Development dependencies
└── test.txt              # Testing dependencies
```

## Requirements Categories

### 1. CLI Tools Requirements
Located in `requirements/cli-requirements.txt`
- Basic system tools needed for the bash scripts
- No Python dependencies
- Install with your system package manager

### 2. System Requirements
Located in `requirements/system-requirements.txt`
- Detailed system dependencies
- Installation instructions for different OS
- Package manager commands

### 3. Python Package Requirements
Located in `requirements/base.txt`
- Core Python package dependencies
- Install with pip: `pip install -r requirements/base.txt`

### 4. Development Requirements
Located in `requirements/dev.txt`
- Additional packages needed for development
- Install with pip: `pip install -r requirements/dev.txt`

### 5. Testing Requirements
Located in `requirements/test.txt`
- Packages needed for running tests
- Install with pip: `pip install -r requirements/test.txt`

## Installation

### CLI Tools Only
```bash
# Install system requirements (Ubuntu example)
sudo apt-get update
sudo apt-get install $(cat requirements/cli-requirements.txt | grep -v '#')
```

### Python Package
```bash
# Install Python dependencies
pip install -r requirements/base.txt

# For development
pip install -r requirements/dev.txt

# For testing
pip install -r requirements/test.txt
```

## Notes
- The base `requirements.txt` in the root directory is kept for backward compatibility
- Use specific requirement files based on your needs
- System requirements vary by OS - check system-requirements.txt for your OS
