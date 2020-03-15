#!/usr/bin/env bash

EXECUTABLE="`basename $0`"

if [ "$1" == "-?" ]; then
cat <<EOF
NAME
   $EXECUTABLE - Creates Unix man files in the geode-addon distribution

SYNOPSIS
   ./$EXECUTABLE [-?]

   Creates Unix man files in the geode-addon distribution. This command
   is executed by the 'build_*.sh' commands. Do not execute it directly.

EOF
   exit
fi

# OS_NAME in uppercase
OS_NAME=`uname`
OS_NAME=`echo "$OS_NAME"|awk '{print toupper($0)}'`

TMP_DIR=build-tmp
MAN_TOP_DIR=share/man
MAN_DIR=$MAN_TOP_DIR/man1

function trimString
{
    local var="$1"
    var="${var##*( )}"
    var="${var%%*( )}"
    echo -n "$var"
}


CREATION_DATE="`date "+%m/%d/%Y"`"

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

# Build man pages
pushd build/geode-addon_${VERSION} > /dev/null 2>&1
if [ ! -d $TMP_DIR ]; then
   mkdir -p $TMP_DIR
fi
if [ ! -d $MAN_DIR ]; then
   mkdir -p $MAN_DIR
fi
for i in bin_sh/*; do
   if [ "$i" == "bin_sh/setenv.sh" ]; then
      continue;
   fi
   COMMANDS="$COMMANDS $i"
done
for i in $COMMANDS; do 
   COMMAND_NAME="`basename $i`"
   $i -? -man > $TMP_DIR/${COMMAND_NAME}.txt
   MAN_FILE=$MAN_DIR/${COMMAND_NAME}.1

   echo ".TH \"$COMMAND_NAME\" \"1\" \"$CREATION_DATE\" \"geode-addon $VERSION\" \"Geode Addon Manual\"" > $MAN_FILE

   section=""
   cluster_in_progress=false
   while IFS= read -r line; do
      if [ "$line" == "WORKSPACE" ]; then
         section="WORKSPACE"
      elif [ "$line" == "NAME" ]; then
         section="NAME"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "SYNOPSIS" ]; then
         section="SYNOPSIS"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "DESCRIPTION" ]; then
         section="DESCRIPTION"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "OPTIONS" ]; then
         section="OPTIONS"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "NOTES" ]; then
         section="NOTES"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "DEFAULT" ]; then
         section="DEFAULT"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "FILES" ]; then
         section="FILES"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "EXAMPLES" ]; then
         section="EXAMPLES"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "SEE ALSO" ]; then
         section="SEE ALSO"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "COMMANDS" ]; then
         section="COMMANDS"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "WARNING" ]; then
         section="WARNING"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "IMPORANT" ]; then
         section="IMPORANT"
         echo ".SH $section" >> $MAN_FILE
         continue
      elif [ "$line" == "CAUTION" ]; then
         section="CAUTION"
         echo ".SH $section" >> $MAN_FILE
         continue
      fi

      # trim string
      line=`trimString "$line"`
      if [ "$section" == "WORKSPACE" ]; then
         continue
      elif [ "$section" == "NAME" ]; then
         echo "$line" >> $MAN_FILE
      elif [ "$section" == "SYNOPSIS" ]; then
         echo "$line" >> $MAN_FILE
      elif [ "$section" == "DESCRIPTION" ]; then
         if [[ $line == minikube* ]]; then
            echo ".IP" >> $MAN_FILE
            echo ".nf" >> $MAN_FILE
            echo "\f[C]" >> $MAN_FILE
            echo "$line" >> $MAN_FILE
         elif [[ $line == gke* ]]; then
            echo "$line" >> $MAN_FILE
            echo "\f[]" >> $MAN_FILE
            echo ".fi" >> $MAN_FILE
            echo ".PP" >> $MAN_FILE
         else
            echo "$line" >> $MAN_FILE
         fi
      elif [ "$section" == "OPTIONS" ]; then
         if [[ $line == \-* ]] || [ "$line" == "app_name" ] || [ "$line" == "cluster_name" ] || [ "$line" == "workspace_name" ]; then  
            echo ".TP" >> $MAN_FILE
            echo ".B $line" >> $MAN_FILE
         elif [[ $line == clusters/* ]] || [[ $line == pods/* ]] || [[ $line == apps/* ]] || [[ $line == minkube* ]]; then
            if [ "$cluster_in_progress" == "false" ]; then
               cluster_in_progress=true
               echo ".RS" >> $MAN_FILE
               echo ".RE" >> $MAN_FILE
               echo ".IP" >> $MAN_FILE
               echo ".nf" >> $MAN_FILE
               echo "\f[C]" >> $MAN_FILE
            fi
            echo "$line" >> $MAN_FILE
         elif [[ $line == https://* ]]; then
            echo ".IP" >> $MAN_FILE
            echo ".nf" >> $MAN_FILE
            echo "\f[C]" >> $MAN_FILE
            echo "$line" >> $MAN_FILE
            echo "\f[]" >> $MAN_FILE
            echo ".fi" >> $MAN_FILE
         else
            if [ "$cluster_in_progress" == "true" ]; then
               cluster_in_progress=false
               echo "\f[]" >> $MAN_FILE
               echo ".fi" >> $MAN_FILE
            fi
            echo "$line" >> $MAN_FILE
         fi
      else
         echo "$line" >> $MAN_FILE
      fi

   done < "$TMP_DIR/${COMMAND_NAME}.txt"
done

WHATIS_CREATED="false"
if [[ ${OS_NAME} == DARWIN* ]]; then
   if [ -f /usr/libexec/makewhatis ]; then
      /usr/libexec/makewhatis $MAN_TOP_DIR/
      WHATIS_CREATED="true"
   fi   
elif [ "`which mandb`" != "" ]; then
   mandb $MAN_TOP_DIR/
   WHATIS_CREATED="true"
fi
if [ -d $TMP_DIR ]; then
   rm -r $TMP_DIR
fi
if [ "$WHATIS_CREATED" == "false" ]; then
   echo ""
   echo "create_man_files:"
   echo "WARNING: Unable to create whatis database due to 'makewhatis' not available in this OS."
   echo ""
fi
popd > /dev/null 2>&1
