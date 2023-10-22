echo Start build...
xcodebuild clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

echo Cleaning previous build..
cd build/Release-iphoneos
rm -rf Payload
rm Discord.ipa
echo Packing build...
mkdir Payload
mv Discord.app Payload
zip -r Discord.ipa Payload

echo Build Done!
