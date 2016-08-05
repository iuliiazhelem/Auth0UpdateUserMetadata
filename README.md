# Auth0UpdateUserMetadata
Test example for updating user metadata

Please make sure that you change some keys in Info.plist with your data:
- Auth0ClientId
- Auth0Domain
- CFBundleURLSchemes

<key>CFBundleTypeRole</key>
<string>None</string>
<key>CFBundleURLName</key>
<string>auth0</string>
<key>CFBundleURLSchemes</key>
<array>
<string>a01038202126265858</string>
</array>

a01038202126265858 -> a0<Auth0ClientId>

Please use your Auth0 APIv2 token from https://auth0.com/docs/api/management/v2/tokens
with scope : update:users

static NSString *kAuth0APIv2Token = <Auth0 APIv2>


For Swift example please change data in Auth0.plist:
- ClientId (your Auth0ClientId)
- Domain (your Auth0Domain)
