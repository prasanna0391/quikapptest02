#!/usr/bin/env bash
set -e
echo "🔧 Initializing Android Gradle Wrapper for compatibility..."

cd android

# Check Java availability
echo "🔍 Checking Java installation..."
if ! command -v java >/dev/null 2>&1; then
    echo "❌ Java is not installed or not in PATH"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
echo "✅ Java version: $JAVA_VERSION"

# Create gradle wrapper directory if it doesn't exist
mkdir -p gradle/wrapper

# Try GitHub first, then fallback to Maven Central
echo "📥 Downloading gradle-wrapper.jar..."
if ! curl -L -o gradle/wrapper/gradle-wrapper.jar \
    "https://github.com/gradle/gradle/raw/v8.12.0/gradle/wrapper/gradle-wrapper.jar"; then
    echo "⚠️  GitHub download failed, trying Maven Central..."
    curl -L -o gradle/wrapper/gradle-wrapper.jar \
        "https://repo1.maven.org/maven2/org/gradle/gradle-wrapper/8.12/gradle-wrapper-8.12.jar"
fi

# Create gradle-wrapper.properties
echo "📝 Creating gradle-wrapper.properties..."
cat > gradle/wrapper/gradle-wrapper.properties <<EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# Create gradlew script
echo "📝 Creating gradlew script..."
cat > gradlew << 'EOF'
#!/bin/sh
# Gradle start up script for UN*X

# Attempt to set APP_HOME
PRG="$0"
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`
DEFAULT_JVM_OPTS="-Xmx64m -Xms64m"
MAX_FD="maximum"

warn () {
    echo "$*"
}

die () {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support
cygwin=false
msys=false
darwin=false
nonstop=false
case "`uname`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
  NONSTOP* )
    nonstop=true
    ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME"
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH."
fi

# Increase the maximum file descriptors if we can
if [ "$cygwin" = "false" -a "$darwin" = "false" -a "$nonstop" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ $? -eq 0 ] ; then
        if [ "$MAX_FD" = "maximum" -o "$MAX_FD" = "max" ] ; then
            MAX_FD="$MAX_FD_LIMIT"
        fi
        ulimit -n $MAX_FD
        if [ $? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: $MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: $MAX_FD_LIMIT"
    fi
fi

# For Darwin, add dock options
if [ "$darwin" = "true" ]; then
    GRADLE_OPTS="$GRADLE_OPTS -Xdock:name=$APP_NAME -Xdock:icon=$APP_HOME/media/gradle.icns"
fi

# For Cygwin or MSYS, switch paths to Windows format
if [ "$cygwin" = "true" -o "$msys" = "true" ] ; then
    APP_HOME=`cygpath --path --mixed "$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "$CLASSPATH"`
    JAVACMD=`cygpath --unix "$JAVACMD"`
fi

# Split up the JVM_OPTS And GRADLE_OPTS values into an array, following the shell quoting and substitution rules
function splitJvmOpts() {
    JVM_OPTS=("$@")
}
eval splitJvmOpts $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS
JVM_OPTS[${#JVM_OPTS[*]}]="-Dorg.gradle.appname=$APP_BASE_NAME"

# Execute Gradle
exec "$JAVACMD" "${JVM_OPTS[@]}" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
EOF

# Make gradlew executable
echo "🔒 Making gradlew executable..."
chmod +x gradlew

# Verify the wrapper setup
echo "🔍 Verifying Gradle wrapper setup..."
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "❌ gradle-wrapper.jar not found"
    exit 1
fi

if [ ! -f "gradle/wrapper/gradle-wrapper.properties" ]; then
    echo "❌ gradle-wrapper.properties not found"
    exit 1
fi

if [ ! -f "gradlew" ]; then
    echo "❌ gradlew script not found"
    exit 1
fi

# Test the wrapper
echo "🔍 Testing Gradle wrapper..."
if ./gradlew --version; then
    echo "✅ Gradle wrapper is working correctly"
else
    echo "⚠️  Gradle wrapper test failed, but files are present"
    echo "📋 Gradle wrapper file sizes:"
    ls -la gradle/wrapper/
    echo "📋 Java version:"
    java -version || echo "Java not found"
fi

cd ..
echo "✅ Gradle wrapper initialization complete" 