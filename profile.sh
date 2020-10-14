#!/bin/sh

# https://github.com/apple/swift/blob/master/docs/CompilerPerformance.md#diagnostic-options

ARTIFACTS_DIR=./ProfilingArtifacts

# =============================
# Utility functions
# =============================

function testForLogFile {
  if [ ! -f "$ARTIFACTS_DIR/build-profile.log" ]; then
    echo "$ARTIFACTS_DIR/build-profile.log does not exist."
    echo "Run build first."
    exit 1
  fi
}

function ensureArtifactsDirExists {
  mkdir -p $ARTIFACTS_DIR
}

# =============================
# Private functions
# =============================

function _buildAndLog {
  ensureArtifactsDirExists
  echo "Building..."
  xcodebuild \
    -workspace "Slide for Reddit.xcworkspace" \
    -scheme "Slide for Reddit" \
    -configuration "Debug" \
    -destination "generic/platform=iOS" \
    -showBuildTimingSummary \
    clean build \
    OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-compilation -Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking" | \
    tee $ARTIFACTS_DIR/build-profile.log
  echo "Build complete."
  echo "Output has been captured in $ARTIFACTS_DIR/build-profile.log"
}

# =============================
# Public functions
# =============================

function build {
  time _buildAndLog
}

function run_xclogparser {
  if ! type "xclogparser" > /dev/null; then
    echo "XCLogParser is not installed!"
    exit 1
  fi

  # _buildAndLog
  # Create xclogparser output from existing build | extract path of output | open output path in browser
  xclogparser parse --project Slide_for_Reddit --reporter html | awk 'NF>1{print $NF}' | xargs -I{} open {}  
}

function step1 {
  printBuildTimingSummary
}

function step2 {
  printDebugCompilationTiming
}

function step3 {
  printSlowestFunctionBodies
}

# https://irace.me/swift-profiling
# Print top 20 slowest function bodies
function printCulprits {
  testForLogFile
  grep .[0-9]ms $ARTIFACTS_DIR/build-profile.log | 
    grep -v ^0.[0-9]ms | 
    sort -nr | 
    head -100
}

function printBadCulprits {
  testForLogFile
  grep .[0-9]ms $ARTIFACTS_DIR/build-profile.log | 
    grep -v ^([0-9]{1,3}).[0-9]ms | 
    sort -nr | 
    head -100
}

# https://github.com/fastred/Optimizing-Swift-Build-Times
# function printSlowest {
#   awk '/Driver Compilation Time/,/Total$/ { print }' $ARTIFACTS_DIR/build-profile.log | \
#     grep compile | \
#     cut -c 55- | \
#     sed -e 's/^ *//;s/ (.*%)  compile / /;s/ [^ ]*Bridging-Header.h$//' | \
#     sed -e "s|$(pwd)/||" | \
#     sort -rn
# }

# Step 1
function printBuildTimingSummary {
  testForLogFile
  cat $ARTIFACTS_DIR/build-profile.log | sed -n -e '/Build Timing Summary/,$p'
}

# Step 2
function printDebugCompilationTiming {
  testForLogFile
  awk '/CompileSwift normal/,/Swift compilation/{print; getline; print; getline; print}' $ARTIFACTS_DIR/build-profile.log |
    grep -Eo "^CompileSwift.+\.swift|\d+\.\d+ seconds" |
    sed -e 'N;s/\(.*\)\n\(.*\)/\2 \1/' |
    sed -e "s|CompileSwift normal x86_64 $(pwd)/||" |
    sort -rn |
    head -3
}

# Step 3
function printSlowestFunctionBodies {
  testForLogFile
  grep -o "^\d*.\d*ms\t[^$]*$" $ARTIFACTS_DIR/build-profile.log |
    awk '!visited[$0]++' |
    sed -e "s|$(pwd)/||" |
    sort -rn |
    head -5
}



# cat build-profile-2.log |
#   grep -o "^\d*.\d*ms\t[^$]*$" |
#   awk '!visited[$0]++' |
#   sed -e "s|$(pwd)/||" |
#   sort -rn |
#   head -50

eval $1