#!/usr/bin/env bash

[[ $# = 0 ]] && echo "No Input" && exit 1

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
# Create input & working directory if it does not exist
mkdir -p "$PROJECT_DIR"/input "$PROJECT_DIR"/working

# download or copy from local?
if echo "$1" | grep -e '^\(https\?\|ftp\)://.*$' > /dev/null; then
    URL=$1
    cd "$PROJECT_DIR"/input || exit
    { type -p aria2c > /dev/null 2>&1 && printf "Downloading File...\n" && aria2c -x16 -j"$(nproc)" "${URL}"; } || { printf "Downloading File...\n" && wget -q --show-progress --progress=bar:force "${URL}" || exit 1; }
    detox "${URL##*/}"
else
    URL=$(printf "%s\n" "$1")
    [[ -e "$URL" ]] || { echo "Invalid Input" && exit 1; }
fi

FILE=$(echo ${URL##*/} | inline-detox)
EXTENSION=$(echo ${URL##*.} | inline-detox)
UNZIP_DIR=${FILE/.$EXTENSION/}
PARTITIONS="system systemex system_ext system_other vendor cust odm odm_ext oem factory product modem xrom oppo_product opproduct reserve india my_preload my_odm my_stock my_operator my_country my_product my_company my_engineering my_heytap"

if [[ -d "$1" ]]; then
    echo 'Directory detected. Copying...'
    cp -a "$1" "$PROJECT_DIR"/working/"${UNZIP_DIR}"
elif [[ -f "$1" ]]; then
    echo 'File detected. Copying...'
    cp -a "$1" "$PROJECT_DIR"/input/"${FILE}" > /dev/null 2>&1
fi

# clone external tools
EXTERNAL_TOOLS=(
    https://github.com/AndroidDumps/Firmware_extractor
    https://github.com/xiaolu/mkbootimg_tools
    https://github.com/marin-m/vmlinux-to-elf
)

for tool_url in "${EXTERNAL_TOOLS[@]}"; do
    tool_path="${PROJECT_DIR}/${tool_url##*/}"
    if ! [[ -d ${tool_path} ]]; then
        git clone -q "${tool_url}" "${tool_path}"
    else
        git -C "${tool_path}" pull
    fi
done

[[ ! -e "${PROJECT_DIR}"/extract-ikconfig ]] && curl https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-ikconfig > ${PROJECT_DIR}/extract-ikconfig

# extract rom via Firmware_extractor
[[ ! -d "$1" ]] && bash "$PROJECT_DIR"/Firmware_extractor/extractor.sh "$PROJECT_DIR"/input/"${FILE}" "$PROJECT_DIR"/working/"${UNZIP_DIR}"

# extract PARTITIONS
cd "$PROJECT_DIR"/working/"${UNZIP_DIR}" || exit
for p in $PARTITIONS; do
    if [[ -e "$p.img" ]]; then
        mkdir "$p" 2> /dev/null || rm -rf "${p:?}"/*
        echo "Extracting $p partition"
        7z x "$p".img -y -o"$p"/ > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            rm "$p".img > /dev/null 2>&1
        else 
        #handling e.g. erofs images, which can't be handled by 7z
            if [ -f $p.img ] && [ $p != "modem" ]; then
                echo "Couldn't extract $p partition by 7z binary. Script will try to mount it instead (sudo password might be needed once)"
                rm -rf "${p}"/* # to avoid "cannot overwrite non-directory 'system/system' with directory 'system_/system'" error
                mkdir "${p}_/" || rm -rf "${p:?}"/*
                sudo mount -t auto -o loop "$p".img "${p}_/"
                if [ $? -eq 0 ]; then
                    sudo cp -rf "${p}_/"* "${p}"
                    sudo umount "${p}_/"
                    sudo rm -rf "${p}_/"
                    rm -fv "$p".img > /dev/null 2>&1
                    sudo chown $(whoami) "${p}/" -R
                else
                    echo "Couldn't extract $p partition. It might use an unsupported filesystem. For EROFS: make sure you're using Linux 5.4+ kernel"
                fi
            fi
        fi
    fi
done

# Bail out right now if no system build.prop
ls system/build*.prop 2> /dev/null || ls system/system/build*.prop 2> /dev/null || {
    terminate 1
}

# Extract bootimage and dtbo
if [[ -f "./boot.img" ]]; then
    mkdir -v bootdts
    "${PROJECT_DIR}"/mkbootimg_tools/mkboot ./boot.img ./bootimg > /dev/null
    extract-dtb ./boot.img -o ./bootimg > /dev/null
    find ./bootimg/ -name '*.dtb' -type f -exec dtc -q -I dtb -O dts {} -o ./bootdts/"$(echo {} | sed 's/\.dtb/.dts/')" \;
    # Extract ikconfig
    if [[ "$(command -v extract-ikconfig)" ]]; then
        extract-ikconfig boot.img > ikconfig
    fi
    # Kallsyms
    python3 "${PROJECT_DIR}"/vmlinux-to-elf/kallsyms-finder ./bootimg/kernel > ./kallsyms.txt
    # ELF
    python3 "${PROJECT_DIR}"/vmlinux-to-elf/vmlinux-to-elf ./bootimg/kernel ./boot.elf
fi
if [[ -f "vendor_boot.img" ]]; then
    mkdir -v vbootdts
    "${PROJECT_DIR}"/mkbootimg_tools/mkboot ./vendor_boot.img ./vbootimg > /dev/null
    extract-dtb ./boot.img -o ./vbootimg > /dev/null
    find vbootimg/ -name '*.dtb' -type f -exec dtc -q -I dtb -O dts {} -o bootdts/"$(echo {} | sed 's/\.dtb/.dts/')" \;
    # Extract ikconfig
    if [[ "$(command -v extract-ikconfig)" ]]; then
        extract-ikconfig boot.img > ikconfig
    fi
    # Kallsyms
    python3 "${PROJECT_DIR}"/vmlinux-to-elf/kallsyms-finder ./vbootimg/kernel > vkallsyms.txt
    # ELF
    python3 "${PROJECT_DIR}"/vmlinux-to-elf/vmlinux-to-elf ./vbootimg/kernel vboot.elf
fi
if [[ -f "dtbo.img" ]]; then
    mkdir -v dtbodts
    extract-dtb ./dtbo.img -o ./dtbo > /dev/null
    find dtbo/ -name '*.dtb' -type f -exec dtc -I dtb -O dts {} -o dtbodts/"$(echo {} | sed 's/\.dtb/.dts/')" \; > /dev/null 2>&1
fi

# Oppo/Realme devices have some images in a euclid folder in their vendor, extract those for props
for dir in "vendor/euclid" "system/system/euclid"; do
    [[ -d ${dir} ]] && {
        pushd "${dir}" || terminate 1
        for f in *.img; do
            [[ -f $f ]] || continue
            7z x "$f" -o"${f/.img/}"
            rm -fv "$f"
        done
        popd || terminate 1
    }
done

# board-info.txt
find ./modem -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> ./board-info.txt
find ./tz* -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> ./board-info.txt
if [ -f ./vendor/build.prop ]; then
    strings ./vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> ./board-info.txt
fi
sort -u -o ./board-info.txt ./board-info.txt

flavor=$(grep -m1 -oP "(?<=^ro.build.flavor=).*" -hs {vendor,system,system/system}/build.prop)
[[ -z ${flavor} ]] && flavor=$(grep -m1 -oP "(?<=^ro.vendor.build.flavor=).*" -hs vendor/build*.prop)
[[ -z ${flavor} ]] && flavor=$(grep -m1 -oP "(?<=^ro.build.flavor=).*" -hs {vendor,system,system/system}/build*.prop)
[[ -z ${flavor} ]] && flavor=$(grep -m1 -oP "(?<=^ro.system.build.flavor=).*" -hs {system,system/system}/build*.prop)
[[ -z ${flavor} ]] && flavor=$(grep -m1 -oP "(?<=^ro.build.type=).*" -hs {system,system/system}/build*.prop)

release=$(grep -m1 -oP "(?<=^ro.build.version.release=).*" -hs {vendor,system,system/system}/build*.prop)
[[ -z ${release} ]] && release=$(grep -m1 -oP "(?<=^ro.vendor.build.version.release=).*" -hs vendor/build*.prop)
[[ -z ${release} ]] && release=$(grep -m1 -oP "(?<=^ro.system.build.version.release=).*" -hs {system,system/system}/build*.prop)
release=$(echo "$release" | head -1)

id=$(grep -m1 -oP "(?<=^ro.build.id=).*" -hs {vendor,system,system/system}/build*.prop)
[[ -z ${id} ]] && id=$(grep -m1 -oP "(?<=^ro.vendor.build.id=).*" -hs vendor/build*.prop)
[[ -z ${id} ]] && id=$(grep -m1 -oP "(?<=^ro.system.build.id=).*" -hs {system,system/system}/build*.prop)
id=$(echo "$id" | head -1)

incremental=$(grep -m1 -oP "(?<=^ro.build.version.incremental=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
[[ -z ${incremental} ]] && incremental=$(grep -m1 -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs vendor/build*.prop)
[[ -z ${incremental} ]] && incremental=$(grep -m1 -oP "(?<=^ro.system.build.version.incremental=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z ${incremental} ]] && incremental=$(grep -m1 -oP "(?<=^ro.build.version.incremental=).*" -hs my_product/build*.prop)
[[ -z ${incremental} ]] && incremental=$(grep -m1 -oP "(?<=^ro.system.build.version.incremental=).*" -hs my_product/build*.prop)
[[ -z ${incremental} ]] && incremental=$(grep -m1 -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs my_product/build*.prop)
incremental=$(echo "$incremental" | head -1)

tags=$(grep -m1 -oP "(?<=^ro.build.tags=).*" -hs {vendor,system,system/system}/build*.prop)
[[ -z ${tags} ]] && tags=$(grep -m1 -oP "(?<=^ro.vendor.build.tags=).*" -hs vendor/build*.prop)
[[ -z ${tags} ]] && tags=$(grep -m1 -oP "(?<=^ro.system.build.tags=).*" -hs {system,system/system}/build*.prop)
tags=$(echo "$tags" | head -1)

platform=$(grep -m1 -oP "(?<=^ro.board.platform=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
[[ -z ${platform} ]] && platform=$(grep -m1 -oP "(?<=^ro.vendor.board.platform=).*" -hs vendor/build*.prop)
[[ -z ${platform} ]] && platform=$(grep -m1 -oP rg"(?<=^ro.system.board.platform=).*" -hs {system,system/system}/build*.prop)
platform=$(echo "$platform" | head -1)

manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs odm/etc/fingerprint/build.default.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs my_product/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs my_product/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs system/system/euclid/my_product/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.vendor.product.manufacturer=).*" -hs vendor/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.vendor.manufacturer=).*" -hs vendor/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.system.product.manufacturer=).*" -hs {system,system/system}/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.system.manufacturer=).*" -hs {system,system/system}/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.odm.manufacturer=).*" -hs vendor/odm/etc/build*.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs {oppo_product,my_product}/build*.prop | head -1)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs vendor/euclid/*/build.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.system.product.manufacturer=).*" -hs vendor/euclid/*/build.prop)
[[ -z ${manufacturer} ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.product.manufacturer=).*" -hs vendor/euclid/product/build*.prop)
manufacturer=$(echo "$manufacturer" | head -1)

fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs odm/etc/fingerprint/build.default.prop)
[[ -z ${fingerprint} ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs vendor/build.prop)
[[ -z ${fingerprint} ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
[[ -z ${fingerprint} ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.product.build.fingerprint=).*" -hs product/build*.prop)
[[ -z ${fingerprint} ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.system.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
[[ -z ${fingerprint} ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z ${fingerprint} ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.system.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z ${fingerprint} ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs my_product/build.prop)
fingerprint=$(echo "$fingerprint" | head -1)

brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs odm/etc/fingerprint/build.default.prop)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs my_product/build*.prop)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs my_product/build*.prop)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs system/system/euclid/my_product/build*.prop)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.vendor.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.vendor.product.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.system.brand=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z ${brand} || ${brand} == "OPPO" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.system.brand=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.product.brand=).*" -hs vendor/euclid/product/build*.prop)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.odm.brand=).*" -hs vendor/odm/etc/build*.prop)
[[ -z ${brand} ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs {oppo_product,my_product}/build*.prop | head -1)
[[ -z ${brand} ]] && brand=$(echo "$fingerprint" | cut -d / -f1)

codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -hs odm/etc/fingerprint/build.default.prop)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.vendor.product.device.oem=).*" -hs odm/build.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.vendor.product.device.oem=).*" -hs vendor/euclid/odm/build.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.vendor.device=).*" -hs vendor/build*.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.vendor.product.device=).*" -hs vendor/build*.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.device=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.model=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -hs {oppo_product,my_product}/build*.prop | head -1)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.device=).*" -hs oppo_product/build*.prop)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs my_product/build*.prop)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.product.vendor.device=).*" -hs my_product/build*.prop)
[[ -z ${codename} ]] && codename=$(grep -m1 -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | cut -d - -f1 | head -1)
[[ -z ${codename} ]] && codename=$(echo "$fingerprint" | cut -d / -f3 | cut -d : -f1)
[[ -z $codename ]] && {
    terminate 1
}

description=$(grep -m1 -oP "(?<=^ro.build.description=).*" -hs {system,system/system}/build.prop)
[[ -z ${description} ]] && description=$(grep -m1 -oP "(?<=^ro.build.description=).*" -hs {system,system/system}/build*.prop)
[[ -z ${description} ]] && description=$(grep -m1 -oP "(?<=^ro.vendor.build.description=).*" -hs vendor/build.prop)
[[ -z ${description} ]] && description=$(grep -m1 -oP "(?<=^ro.vendor.build.description=).*" -hs vendor/build*.prop)
[[ -z ${description} ]] && description=$(grep -m1 -oP "(?<=^ro.product.build.description=).*" -hs product/build.prop)
[[ -z ${description} ]] && description=$(grep -m1 -oP "(?<=^ro.product.build.description=).*" -hs product/build*.prop)
[[ -z ${description} ]] && description=$(grep -m1 -oP "(?<=^ro.system.build.description=).*" -hs {system,system/system}/build*.prop)
[[ -z ${description} ]] && description="$flavor $release $id $incremental $tags"

is_ab=$(grep -m1 -oP "(?<=^ro.build.ab_update=).*" -hs {system,system/system,vendor}/build*.prop)
is_ab=$(echo "$is_ab" | head -1)
[[ -z ${is_ab} ]] && is_ab="false"

codename=$(echo "$codename" | tr ' ' '_')
branch=$(echo "$description" | head -1 | tr ' ' '-')
repo_subgroup=$(echo "$brand" | tr '[:upper:]' '[:lower:]')
[[ -z $repo_subgroup ]] && repo_subgroup=$(echo "$manufacturer" | tr '[:upper:]' '[:lower:]')
repo_name=$(echo "$codename" | tr '[:upper:]' '[:lower:]')
repo="$repo_subgroup/$repo_name"
platform=$(echo "$platform" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
top_codename=$(echo "$codename" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
manufacturer=$(echo "$manufacturer" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)

printf "%s\n" "flavor: ${flavor}
release: ${release}
id: ${id}
incremental: ${incremental}
tags: ${tags}
fingerprint: ${fingerprint}
brand: ${brand}
codename: ${codename}
description: ${description}
branch: ${branch}
repo: ${repo}
manufacturer: ${manufacturer}
platform: ${platform}
top_codename: ${top_codename}
is_ab: ${is_ab}" > "$PROJECT_DIR"/working/"${UNZIP_DIR}"/README.md
cat "$PROJECT_DIR"/working/"${UNZIP_DIR}"/README.md

# Fix permissions
sudo chown "$(whoami)" $PROJECT_DIR/working/${UNZIP_DIR}/* -R
sudo chmod -R u+rwX $PROJECT_DIR/working/${UNZIP_DIR}/*

# Generate all_files.txt
find . -type f -printf '%P\n' | sort | grep -v ".git/" > $PROJECT_DIR/working/${UNZIP_DIR}/all_files.txt

echo "Dump done locally."
exit 1
