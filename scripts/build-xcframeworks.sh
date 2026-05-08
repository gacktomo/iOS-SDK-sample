#!/usr/bin/env bash
#
# build-xcframeworks.sh
#
# ChildSDK.xcframework を生成する。UISDK のシンボル + リソースを ChildSDK に
# 静的に焼き込んだ状態で 1 つの XCFramework として出力する。
#
# 仕組み:
#   - UISDK は Package.swift で type: .static のため、archive 時に ChildSDK
#     の binary に静的リンクされる。
#   - UISDK のリソース (index.html) は SPM の resource bundle として
#     UISDK_UISDK.bundle に集約されるが、framework 直下に配置されない。
#     archive 完了後、本スクリプトが手動でコピーする。
#
# 出力:
#   build/ChildSDK.xcframework
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${ROOT}/build"
WORK_DIR="${BUILD_DIR}/work"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${WORK_DIR}"

CONFIGURATION="Release"
PLATFORMS=(
  "iOS:generic/platform=iOS:iphoneos"
  "iOSSim:generic/platform=iOS Simulator:iphonesimulator"
)

##
## archive_module <project> <scheme> <label> <destination> <archive_path> <derived_path>
##
archive_module() {
  local project="$1"
  local scheme="$2"
  local label="$3"
  local destination="$4"
  local archive_path="$5"
  local derived_path="$6"

  echo ">>> Archiving ${scheme} (${label})"
  xcodebuild archive \
    -project "${project}" \
    -scheme "${scheme}" \
    -configuration "${CONFIGURATION}" \
    -destination "${destination}" \
    -archivePath "${archive_path}" \
    -derivedDataPath "${derived_path}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    > "${WORK_DIR}/archive-${scheme}-${label}.log" 2>&1 \
    || { echo "!! archive failed. See ${WORK_DIR}/archive-${scheme}-${label}.log"; tail -50 "${WORK_DIR}/archive-${scheme}-${label}.log"; exit 1; }
}

##
## copy_dependency_resources <derived_path> <framework_path> <bundle_names...>
##
## 指定した resource bundle 内の .html を framework 直下にフラットに配置する。
## SPM の resource bundle (UISDK_UISDK.bundle 等) は archive 直下には来ないので
## DerivedData 内のビルド成果物から拾う。
##
copy_dependency_resources() {
  local derived_path="$1"; shift
  local framework_path="$1"; shift
  for bundle_name in "$@"; do
    local found
    found="$(find "${derived_path}" -name "${bundle_name}" -type d -print -quit 2>/dev/null || true)"
    if [ -n "${found}" ]; then
      echo "    copying resources from ${bundle_name}"
      find "${found}" \( -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.png' -o -name '*.jpg' \) \
        -exec cp {} "${framework_path}/" \;
    fi
  done
}

##
## build_xcframework <project_path> <scheme> <output_xcframework> <dep_bundle_names...>
##
build_xcframework() {
  local project_path="$1"
  local scheme="$2"
  local output="$3"
  shift 3
  local dep_bundles=("$@")

  local framework_args=()
  for entry in "${PLATFORMS[@]}"; do
    local label="${entry%%:*}"; local rest="${entry#*:}"
    local destination="${rest%%:*}"
    local archive_path="${WORK_DIR}/${scheme}-${label}.xcarchive"
    local derived_path="${WORK_DIR}/dd-${scheme}-${label}"

    archive_module "${project_path}" "${scheme}" "${label}" "${destination}" "${archive_path}" "${derived_path}"

    local fw_path="${archive_path}/Products/Library/Frameworks/${scheme}.framework"
    if [ ! -d "${fw_path}" ]; then
      echo "!! ${scheme}.framework not found at ${fw_path}"
      exit 1
    fi

    if [ "${#dep_bundles[@]}" -gt 0 ]; then
      copy_dependency_resources "${derived_path}" "${fw_path}" "${dep_bundles[@]}"
    fi

    # codesign がリソース変更後に CodeResources を持っていると XCFramework 化で
    # 失敗するので、archive 時の ad-hoc 署名を破棄する。
    rm -rf "${fw_path}/_CodeSignature"

    framework_args+=( -framework "${fw_path}" )
  done

  echo ">>> Creating $(basename "${output}")"
  xcodebuild -create-xcframework "${framework_args[@]}" -output "${output}"
}

main() {
  echo "===> Building ChildSDK.xcframework (with UISDK statically embedded)"
  build_xcframework \
    "${ROOT}/ChildSDK/ChildSDK.xcodeproj" \
    "ChildSDK" \
    "${BUILD_DIR}/ChildSDK.xcframework" \
    "UISDK_UISDK.bundle"

  echo
  echo "✅ Build complete:"
  ls -1d "${BUILD_DIR}"/*.xcframework
}

main "$@"
