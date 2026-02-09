#!/bin/bash
set -euxo pipefail

# Only run on the driver
if [[ $DB_IS_DRIVER != "TRUE" ]]; then
    exit 0
fi

ORS_PORT="${ORS_PORT:-8082}"
ORS_HOME="/local_disk0/ors"
ORS_STORE="/Volumes/dmeplan_datalake/routing/"
LOG_DIR="${ORS_HOME}/logs"
PID_FILE="${ORS_HOME}/ors.pid"

mkdir -p "${ORS_HOME}/config" "${ORS_HOME}/files" "${ORS_HOME}/graphs" "${ORS_HOME}/tmp" "$LOG_DIR"

echo "[ORS INIT] Ensure Java is available..."
if ! command -v java >/dev/null 2>&1; then
    apt-get update
    apt-get install -y openjdk-17-jre-headless
fi
java -version

echo "[ORS INIT] Stage jar + config"
cp -f "${ORS_STORE}/config/ors.jar" "${ORS_HOME}/ors.jar"
cp -f "${ORS_STORE}/config/ors-config.yml" "${ORS_HOME}/config/ors-config.yml"

echo "[ORS INIT] Stage input files (PBF + GTFS)..."
cp -f "${ORS_STORE}/files/edited-wmata-extract-from-geofabrik_us-south-latest.osm.pbf" "${ORS_HOME}/files/dmv.osm.pbf"
cp -f "${ORS_STORE}/files/wmata.zip" "${ORS_HOME}/files/wmata.zip"

echo "[ORS INIT] If prebuilt graphs exist in DBFS, sync them down..."
if [[ -d "${ORS_STORE}/graphs" ]]; then
  # rsync is best; if rsync isn't available, you can fall back to cp -r
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${ORS_STORE}/graphs/" "${ORS_HOME}/graphs/"
  else
    rm -rf "${ORS_HOME}/graphs"/*
    cp -r "${ORS_STORE}/graphs/." "${ORS_HOME}/graphs/"
  fi
fi

echo "[ORS INIT] Stop any existing ORS..."
if [[ -f "${PID_FILE}" ]]; then
  OLD_PID="$(cat "${PID_FILE}" || true)"
  if [[ -n "${OLD_PID}" ]] && kill -0 "${OLD_PID}" >/dev/null 2>&1; then
    kill "${OLD_PID}" || true
    sleep 5
  fi
  rm -f "${PID_FILE}"
fi

cd "${ORS_HOME}"

echo "[ORS INIT] Start ORS..."
# Heap sizing: DC + 3 profiles is usually fine with 16–64g depending on driver size and GTFS complexity.
JAVA_HEAP_XMS="${JAVA_HEAP_XMS:-8g}"
JAVA_HEAP_XMX="${JAVA_HEAP_XMX:-32g}"

# Provide config path as a program argument (supported by ORS).  [oai_citation:7‡giscience.github.io](https://giscience.github.io/openrouteservice/run-instance/configuration/how-to-configure)
nohup java \
  -Xms${JAVA_HEAP_XMS} \
  -Xmx${JAVA_HEAP_XMX} \
  -Djava.io.tmpdir="${ORS_HOME}/tmp" \
  -jar "${ORS_HOME}/ors.jar" \
  "${ORS_HOME}/config/ors-config.yml" \
  --server.port="${ORS_PORT}" \
  > "${LOG_DIR}/ors.log" 2>&1 &

echo $! > "${PID_FILE}"
echo "[ORS INIT] ORS PID $(cat "${PID_FILE}") listening on ${ORS_PORT}"
