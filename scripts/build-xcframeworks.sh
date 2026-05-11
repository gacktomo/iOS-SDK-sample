#!/usr/bin/env bash
#
# build-xcframeworks.sh
#
# ChildSDK.xcframework を生成し、配布用 zip を組み立てる。
# UISDK のシンボル + リソースを ChildSDK に静的に焼き込んだ
# static XCFramework として出力する。
#
# 仕組み:
#   - UISDK は Package.swift で type: .static のため、archive 時に ChildSDK
#     の binary に静的リンクされる。
#   - UISDK のリソース (index.html) は SPM の resource bundle として
#     UISDK_UISDK.bundle に集約されるが、framework 直下に配置されない。
#     archive 完了後、本スクリプトが手動でコピーする。
#
# 環境変数:
#   VERSION  配布バージョン文字列。未指定なら git describe / "dev" にフォールバック。
#
# 出力:
#   build/ChildSDK.xcframework
#   build/ChildSDK-<version>.zip           (xcframework + dist/README.md)
#   build/ChildSDK-<version>.zip.sha256    (SPM binaryTarget 用 checksum)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${ROOT}/build"
WORK_DIR="${BUILD_DIR}/work"
DIST_DIR="${ROOT}/dist"

VERSION="${VERSION:-$(git -C "${ROOT}" describe --tags --always --dirty 2>/dev/null || echo dev)}"

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

##
## package_zip
##
## ChildSDK.xcframework + dist/ 配下のドキュメントを zip にまとめ、
## SPM binaryTarget 用の checksum も算出する。
##
package_zip() {
  local stage_dir="${WORK_DIR}/stage"
  local zip_name="ChildSDK-${VERSION}.zip"
  local zip_path="${BUILD_DIR}/${zip_name}"

  echo ">>> Packaging ${zip_name}"
  rm -rf "${stage_dir}"
  mkdir -p "${stage_dir}"

  # XCFramework
  cp -R "${BUILD_DIR}/ChildSDK.xcframework" "${stage_dir}/"

  # 配布ドキュメント (dist/ 直下を丸ごと取り込む)
  if [ -d "${DIST_DIR}" ]; then
    find "${DIST_DIR}" -maxdepth 1 -type f -exec cp {} "${stage_dir}/" \;
  fi

  # zip (シンボリックリンクを保持しないと XCFramework が壊れる)
  ( cd "${stage_dir}" && zip -ry "${zip_path}" . > /dev/null )

  # checksum (SPM binaryTarget の url で参照する場合に使う)
  if command -v swift >/dev/null 2>&1; then
    swift package --package-path "${ROOT}/ChildSDK" compute-checksum "${zip_path}" > "${zip_path}.sha256" 2>/dev/null \
      || shasum -a 256 "${zip_path}" | awk '{print $1}' > "${zip_path}.sha256"
  else
    shasum -a 256 "${zip_path}" | awk '{print $1}' > "${zip_path}.sha256"
  fi
}

main() {
  echo "===> Building ChildSDK.xcframework (version: ${VERSION})"
  build_xcframework \
    "${ROOT}/ChildSDK/ChildSDK.xcodeproj" \
    "ChildSDK" \
    "${BUILD_DIR}/ChildSDK.xcframework" \
    "UISDK_UISDK.bundle"

  package_zip

  echo
  echo "✅ Build complete:"
  ls -1 "${BUILD_DIR}/ChildSDK.xcframework" "${BUILD_DIR}"/ChildSDK-*.zip "${BUILD_DIR}"/ChildSDK-*.zip.sha256 2>/dev/null | sed 's/^/  /'
  echo
  echo "📦 Zip top-level contents:"
  unzip -Z1 "${BUILD_DIR}/ChildSDK-${VERSION}.zip" | awk -F/ '{print $1}' | sort -u | sed 's/^/  /'
  echo
  echo "🔐 Checksum:"
  echo "  $(cat "${BUILD_DIR}/ChildSDK-${VERSION}.zip.sha256")"
}

main "$@"
