#!/bin/bash

# Default values
DEFAULT_PROJECT_NAME="dojo_exercise"
DEFAULT_KOTLIN_VERSION="2.2.0"
DEFAULT_GRADLE_VERSION="8.12"
DEFAULT_JDK_VERSION=17

# Prompt for project name with default
read -p "Enter the name of your Kotlin project [default: $DEFAULT_PROJECT_NAME]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}

# Prompt for Kotlin version with default
read -p "Enter Kotlin version [default: $DEFAULT_KOTLIN_VERSION]: " KOTLIN_VERSION
KOTLIN_VERSION=${KOTLIN_VERSION:-$DEFAULT_KOTLIN_VERSION}

# Prompt for Gradle version with default
read -p "Enter Gradle version [default: $DEFAULT_GRADLE_VERSION]: " GRADLE_VERSION
GRADLE_VERSION=${GRADLE_VERSION:-$DEFAULT_GRADLE_VERSION}

# Prompt for JDK version with default
read -p "Enter JDK version [default: $DEFAULT_JDK_VERSION]: " JDK_VERSION
JDK_VERSION=${JDK_VERSION:-$DEFAULT_JDK_VERSION}

# Check if gh (a GitHub command line client) is installed, if not install it
if ! command -v gh &> /dev/null
then
    echo "gh could not be found, installing via Homebrew."
    brew install gh
fi

# Check if ktlint (a linter for Kotlin) is installed, if not install it
if ! command -v ktlint &> /dev/null
then
    echo "ktlint could not be found, installing via Homebrew."
    brew install ktlint
fi

# Create the directory structure
mkdir -p "$PROJECT_NAME/src/main/kotlin"
mkdir -p "$PROJECT_NAME/src/test/kotlin"
mkdir -p "$PROJECT_NAME/.githooks"

# Create build.gradle.kts
cat > "$PROJECT_NAME/build.gradle.kts" <<EOL
plugins {
    kotlin("jvm") version "$KOTLIN_VERSION"
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of($JDK_VERSION))
    }
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(kotlin("test"))
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.0")
}

tasks.test {
    useJUnitPlatform()
}
EOL

# Create settings.gradle.kts
cat > "$PROJECT_NAME/settings.gradle.kts" <<EOL
rootProject.name = "$PROJECT_NAME"
EOL

# Create Main.kt
cat > "$PROJECT_NAME/src/main/kotlin/Main.kt" <<EOL
fun main() {
    println("Hello, Kotlin!")
}
EOL

# Create MainTest.kt
cat > "$PROJECT_NAME/src/test/kotlin/MainTest.kt" <<EOL
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals

class MainTest {
    @Test
    fun dummyTest() {
        assertEquals(4, 2 + 2)
    }
}
EOL

# Create README.md
cat > "$PROJECT_NAME/README.md" <<EOL
# $PROJECT_NAME kata
EOL

# Create NOTES.md
cat > "$PROJECT_NAME/NOTES.md" <<EOL
# $PROJECT_NAME kata


## Emojis to use
✅ done
🚧 WIP
❌ ERROR
⚠ TODO

## Steps
EOL

# Create TECHDEBT.md
cat > "$PROJECT_NAME/NOTES.md" <<EOL
# $PROJECT_NAME kata


## Emojis to use
✅ done
🚧 WIP
❌ ERROR
⚠ TODO

## Tech debt
EOL

# Create .gitignore
cat > "$PROJECT_NAME/.gitignore" <<EOL
.gradle/
build/
out/
.idea/
*.iml
*.class
*.war
*.ear
EOL


# Create precommit file
cat > "$PROJECT_NAME/.githooks/pre-commit" <<EOL
#!/bin/sh

# Run ktlint with error handling
if ! ktlint --format; then
  echo "Ktlint formatting failed"
  exit 1
fi
EOL
# Give execution rights to the precommit file
chmod +x $PROJECT_NAME/.githooks/pre-commit

# # Initialize Git repository and make initial commit
cd "$PROJECT_NAME" || exit
git init

# Configure git hooks path
git config core.hooksPath .githooks

git add .
git commit -m "Initial commit"

# Check if gh CLI is authenticated. If not, login to GitHub CLI so that we can push the repository
if ! gh auth status &> /dev/null
then
    echo "You are not logged in to GitHub CLI. Initiating login..."
    gh auth login
fi

# Push the repository to GitHub
gh repo create $PROJECT_NAME --private --source=. --push

# # Set up Gradle Wrapper with the specified version
gradle wrapper --gradle-version "$GRADLE_VERSION"

echo "Project $PROJECT_NAME has been set up successfully with Kotlin $KOTLIN_VERSION, Gradle $GRADLE_VERSION, JDK $JDK_VERSION and a Git repo."

# Create GitHub Actions workflow directory
mkdir -p ".github/workflows"

# Create GitHub Actions CI workflow
cat > ".github/workflows/ci.yml" <<EOL
name: Kotlin CI

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up JDK $JDK_VERSION
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: $JDK_VERSION

    - name: Cache Gradle packages
      uses: actions/cache@v3
      with:
        path: ~/.gradle/caches
        key: gradle-\${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
        restore-keys: gradle-

    - name: Grant execute permission for gradlew
      run: chmod +x ./gradlew

    - name: Build and test with Gradle
      run: ./gradlew clean build
EOL

git add .
git commit -m "Add pipeline"
git push

idea .
