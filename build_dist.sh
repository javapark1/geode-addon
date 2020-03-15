#!/usr/bin/env bash

EXECUTABLE="`basename $0`"

if [ "$1" == "-?" ]; then
cat <<EOF
NAME
   $EXECUTABLE - Build geode-addon along with all required files such
                 as Unix man pages

SYNOPSIS
   ./$EXECUTABLE [-?]

   Builds geode-addon along with all required files such as Unix man pages.
   Unlike build_all.sh, it does not build apps.

DEFAULT
   ./$EXECUTABLE

EOF
   exit
fi

# TSLv1.2 required for older version of macOS
mvn clean -Dhttps.protocols=TLSv1.2 -DskipTests install

# Get the addon version number
VERSION=`grep "<version>.*<\/version>" pom.xml` 
# Pick the first version tag.
for i in $VERSION; do
   VERSION=$i
   break;
done
VERSION=${VERSION#<version>}
VERSION=${VERSION%<\/version>}

# Untar the distribution file in the build directory.
if [ ! -d build ]; then
   mkdir -p build
fi

if [ -d build/geode-addon_${VERSION} ]; then
   rm -Rf build/geode-addon_${VERSION}
fi
if [ -d build/geode-addon-all_${VERSION} ]; then
   rm -Rf build/geode-addon-all_${VERSION}
fi
tar -C build/ -xzf geode-addon-deployment/target/assembly/geode-addon_${VERSION}.tar.gz

# Build man pages
chmod 755 ./create_man_files.sh
./create_man_files.sh

# tar up the distribution which now includes man pages
tar -C build -czf geode-addon-deployment/target/assembly/geode-addon_${VERSION}.tar.gz geode-addon_${VERSION}
pushd build > /dev/null 2>&1
zip -q -r ../geode-addon-deployment/target/assembly/geode-addon_${VERSION}.zip geode-addon_${VERSION}
popd > /dev/null 2>&1

echo ""
echo "The following distrubution files have been generated."
echo ""
echo "Cluster Distribution (Light): Some apps need to be built by executing 'bin_sh/build_app'"
echo ""
echo "   geode-addon-deployment/target/assembly/geode-addon_${VERSION}.tar.gz"
echo "   geode-addon-deployment/target/assembly/geode-addon_${VERSION}.zip"
echo ""
