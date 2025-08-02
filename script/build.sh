#!/bin/bash

flutter build ipa --export-options-plist=./ExportOptions.plist
./script/pgyer_upload.sh -k 12abca518c3863367992f9a89ff3bb34 ./build/ios/ipa/情绪日记.ipa