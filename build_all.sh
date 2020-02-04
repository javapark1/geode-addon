#/bin/bash

EXECUTABLE="`basename $0`"

if [ "$1" == "-?" ]; then
cat <<EOF
NAME
   $EXECUTABLE - Build all the apps by executing their 'bin_sh/build_app' command

SYNOPSIS
   ./$EXECUTABLE [-?]

   Builds all the apps by executing their 'bin_sh/build_app' command and creates
   the 'all' distribution file that contains the apps that are fully compiled
   and ready to run.

DEFAULT
   ./$EXECUTABLE

EOF
   exit
fi

mvn clean -DskipTests install

# Get the addon version number
VERSION=`grep "<version>.*<\/version>" pom.xml` 
# Pick the first version tag.
for i in $VERSION; do
   VERSION=$i
   break;
done
VERSION=${VERSION#<version>}
VERSION=${VERSION%<\/version>}
export VERSION

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

# Find all build_app scripts and build them
pushd build/geode-addon_${VERSION} > /dev/null 2>&1
for APP in apps/*; do 
   if [ -f $APP/bin_sh/build_app ]; then
      pushd $APP/bin_sh > /dev/null 2>&1
      chmod 755 ./build_app
      echo ""
      echo "---------------------------------------------------------------------"
      echo "$APP/bin_sh/build_app -clean -all"
      echo "---------------------------------------------------------------------"
      echo ""
      ./build_app -clean -all
      popd > /dev/null 2>&1
   fi
done
popd > /dev/null 2>&1

mv -f build/geode-addon_${VERSION}  build/geode-addon-all_${VERSION}
tar -C build -czf geode-addon-deployment/target/assembly/geode-addon-all_${VERSION}.tar.gz geode-addon-all_${VERSION}
pushd build > /dev/null 2>&1
zip -q -r ../geode-addon-deployment/target/assembly/geode-addon-all_${VERSION}.zip geode-addon-all_${VERSION}
popd > /dev/null 2>&1

echo ""
echo "The following distrubution files have been generated."
echo ""
echo "1. Cluster Distribution (Light): Some apps need to be built by executing 'bin_sh/build_app'"
echo ""
echo "   geode-addon-deployment/target/assembly/geode-addon_${VERSION}.tar.gz"
echo "   geode-addon-deployment/target/assembly/geode-addon_${VERSION}.zip"
echo ""
echo "2. Full Distribution (Heavy): Includes full-blown apps."
echo ""
echo "   geode-addon-deployment/target/assembly/geode-addon-all_${VERSION}.tar.gz"
echo "   geode-addon-deployment/target/assembly/geode-addon-all_${VERSION}.zip"
echo ""
