#!/usr/bin/env bash

function print_help {
    echo "Example usage: bash convert.sh -i ~/Music/FLAC/ -o ~/Music/ALAC/";
    exit 0;
}

function test_dir {
    local DIR=$1
    if ! test -d "${DIR}"; then
        echo "Directory ${DIR} does not exist";
        exit 1;
    fi
}

function convert_to_flac {
    local IN_FLAC="$1";
    local OUT_ALAC="$2";

    if test -f "${OUT_ALAC}"; then
        printf "     File exist: %s\n" "${OUT_ALAC}";
    elif test -f "${IN_FLAC}"; then
        printf "     Converting:\n      %s\n" "${IN_FLAC}";
        printf "     To:\n      %s\n" "${OUT_ALAC}";
        ffmpeg -i "${IN_FLAC}" -y -v 0 -vcodec copy -acodec alac "${OUT_ALAC}";
    fi
}

function convert_to_flac_from_dir {
    local input_dir="$1";
    local output_dir="$2";

    printf "  Converting FLACs in directory:\n    %s\n" "${input_dir}";
    printf "  Outputting ALACs to directory:\n    %s\n" "${output_dir}";

    test -d "${output_dir}" || mkdir -p "${output_dir}";

    rsync -av --exclude "*.flac" "${input_dir}" "${output_dir}" >/dev/null 2>&1

    local FLACS=("${input_dir}"*.flac);

    for flac_file in "${FLACS[@]}"; do
        local flac_name="${flac_file#"${input_dir}"}";
        local alac_name="${flac_name%".flac"}".m4a;
        convert_to_flac "${flac_file}" "${output_dir}${alac_name}";
    done
}

function process_directory {
    local IN_FILE="$1";
    local OUT_DIR="$2";
    local INDIR="$3";

    local FILES=("${IN_FILE}"*);

    for FILE in "${FILES[@]}"; do
        if test -d "${FILE}"; then
            printf "Processing directory:\n %s\n" "${FILE#"${INDIR}"}";
            convert_to_flac_from_dir "${FILE}/" "${OUT_DIR%"/"}${FILE#"${INDIR}"}/";
            process_directory "${FILE}/" "${OUT_DIR}" "${INDIR}";
        fi
    done
}

function parse_args {
    local ARGC=$(( $# - 1 ));
    local ARGV=("$@");

    local -n INDIR="$1";
    local -n OUTDIR="$2";

    [ $ARGC -le 1 ] && exit 1;

    for i in $(seq 2 "${ARGC}"); do
        if [ "${ARGV[$i]}" = "-h" ] || [ "${ARGV[$i]}" = "--help" ]; then
            print_help;
        elif [ "${ARGV[$i]}" = "-i" ] || [ "${ARGV[$i]}" = "--indir" ]; then
            INDIR="${ARGV[$(( i + 1 ))]%$"/"}";
            test_dir "${INDIR}";
        elif [ "${ARGV[$i]}" = "-o" ] || [ "${ARGV[$i]}" = "--outdir" ]; then
            OUTDIR="${ARGV[$(( i + 1 ))]}";
            test -d "${OUTDIR}" || mkdir -p "${OUTDIR}";
        else
            exit 1;
        fi
    done
}

function main {
    local ARGC="$#";
    local ARGV=("$@");

    local indir;
    local outdir;

    parse_args indir outdir "${ARGV[@]}";
    process_directory "${indir}" "${outdir}" "${indir}";
}


main "$@";
