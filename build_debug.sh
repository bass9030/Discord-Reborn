echo Start build...
xcodebuild clean build -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

echo Cleaning previous build..
cd build/Debug-iphoneos
rm -rf Payload
rm Discord.ipa
echo Packing build...
mkdir Payload
mv Discord.app Payload
zip -r Discord-Debug.ipa Payload

echo Build Done!
