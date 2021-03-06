#!/bin/sh

# syntax:
# extract_strings.sh [--mailer-repo ./fxa-auth-mailer] [--content-repo ./fxa-content-server] [--l10n-repo ./fxa-content-server-l10n] train_number

set -e

function usage() {
    echo "syntax:"
    echo "extract_strings.sh [--mailer-repo ./fxa-auth-mailer] [--content-repo ./fxa-content-server] [--l10n-repo ./fxa-content-server-l10n] train_number"
    exit 1
}

function check_folder() {
    if [[ ! -d $1 ]]; then
        echo "Error: No such directory"
        exit 1
    else
        echo "Ok!"
    fi
}

if [[ $# -lt 1 ]]; then
    usage;
fi

MAILER_DIR="./fxa-auth-mailer"
CONTENT_DIR="./fxa-content-server"
L10N_DIR="./fxa-content-server-l10n"

while [[ $# > 1 ]]
do
param="$1"

case $param in
    --mailer-repo)
    MAILER_DIR="$2"
    shift 2
    ;;
    --content-repo)
    CONTENT_DIR="$2"
    shift 2
    ;;
    --l10n-repo)
    L10N_DIR="$2"
    shift 2
    ;;
    *)
    usage
    ;;
esac
done

if [[ ! $1 =~ ^[0-9]+$ ]]; then
    usage;
fi

TRAIN_NUMBER=$1

printf "Checking $MAILER_DIR.. "
check_folder $MAILER_DIR
printf "Checking $CONTENT_DIR.. "
check_folder $CONTENT_DIR
printf "Checking $L10N_DIR.. "
check_folder $L10N_DIR

set -x

(cd $MAILER_DIR && grunt l10n-extract)
cp $MAILER_DIR/server.pot $CONTENT_DIR/locale/templates/LC_MESSAGES/

(cd $CONTENT_DIR && grunt l10n-extract)
cp -r $CONTENT_DIR/locale/templates/ $L10N_DIR/locale/templates

cd $L10N_DIR
git checkout -b merge-train-$TRAIN_NUMBER-strings
./scripts/merge_po.sh ./locale
git add .
git commit -m "merge strings for train $TRAIN_NUMBER"

set +x

echo
echo
echo "Everything seems to be in order. Please check the extraction went okay then you can push the new branch with:"
echo "cd $L10N_DIR"
echo "git push <remote> merge-train-$TRAIN_NUMBER-strings"
