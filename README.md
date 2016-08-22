# Auth0UpdateUserMetadata
This sample exposes how to create and update user metadata.

Auth0 allows you to store `metadata`, or data related to each user that has not come from the identity provider.
NOTE: An authenticated user can modify data in their profile's `user_metadata`, but not in their `app_metadata`. For more details please see [link](https://auth0.com/docs/metadata).

## Swift
If you use Swift you can implemet creation and updating user metadata with [Auth0.swift Toolkit for Auth0 API](https://github.com/auth0/Auth0.swift).

For this you need to add the following to your `Podfile`:
```
pod 'Auth0', '~> 1.0.0-beta.7'
```

Also please change data in Auth0.plist:
- ClientId (your Auth0ClientId)
- Domain (your Auth0Domain)

### Important Snippets
####Signup with user metadata
```swift
        let usermetadata = ["first_name": "support", "last_name" : "Auth0", "age" : "29"]
        Auth0
            .authentication()
            .signUp(email: "example@example.com", username: nil, password: "examplePassword", connection: "Username-Password-Authentication", userMetadata: usermetadata)
            .start { result in
                switch result {
                case .Success(let credentials):
                    print("id_token: \(credentials.idToken)")
                case .Failure(let error):
                    print(error)
                }
        }
```

####Update user metadata
```Swift
        let attributes = ["name": "Test", "country": "Ukraine"]
        Auth0
          .users(token: actualToken)
          .patch(actualUserId, userMetadata: attributes)
          .start { result in
            switch result {
              case .Success(let profile):
                let metadata = profile["user_metadata"]
                print("metadata: \(metadata)")
              case .Failure(let error):
                print(error)
            }
          }
```

## Objective-C
For Objective-C you need to get Auth0 APIv2 token from this [link](https://auth0.com/docs/api/management/v2/tokens)
with scope `update:users` and use it in code
`static NSString *kAuth0APIv2Token = Your_APIv2_Token`
For updating user metadata you need to make PATCH http request using [APIv2](https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id)

### Important Snippets
####Update user metadata
```Objective-C
    NSString *token = [NSString stringWithFormat:@"Bearer %@", kAuth0APIv2Token];
    NSDictionary *headers = @{ @"content-type": @"application/json",
                               @"Authorization": token};
    NSDictionary *body = @{ @"user_metadata" : @{
                            @"name": @"Test",
                            @"country" : @"Ukraine"
                            }
                          };
    
    NSError *error;
    NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:body
                                                           options:0
                                                             error:&error];
    
    NSString *userId = [self.userId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    
    NSString *urlString = [NSString stringWithFormat:@"https://%@/api/v2/users/%@", [NSBundle mainBundle].infoDictionary[@"Auth0Domain"], userId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setHTTPMethod:@"PATCH"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:dataFromDict];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        NSLog(@"%@", error);
                                                    } else {
                                                        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                                                        if (dict[@"user_metadata"]) {
                                                          //use new user metadata if needed
                                                        }
                                                    }
                                                }];
    [dataTask resume];

```

Please make sure that you change some keys in `Info.plist` with your Auth0 data from [Auth0 Dashboard](https://manage.auth0.com/#/applications):
- Auth0ClientId
- Auth0Domain
- CFBundleURLSchemes

<key>CFBundleTypeRole</key>
<string>None</string>
<key>CFBundleURLName</key>
<string>auth0</string>
<key>CFBundleURLSchemes</key>
<array>
<string>a0{CLIENT_ID}</string>
</array>

For more information about user metadata please check the following links:
- [User profile](https://auth0.com/docs/user-profile)
- [Metadata in rules](https://auth0.com/docs/rules/metadata-in-rules)
- [User metadata](https://auth0.com/docs/metadata)
- [Using Metadata with Management APIv2](https://auth0.com/docs/metadata/apiv2)
