//
//  ViewController.m
//  AKAuth0TestApp
//
//  Created by Iuliia Zhelem on 09.07.16.
//  Copyright © 2016 Akvelon. All rights reserved.
//

#import "ViewController.h"
#import <Lock/Lock.h>

//Please use your Auth0 APIv2 token from https://auth0.com/docs/api/management/v2/tokens
//scopes : update:users
static NSString *kAuth0APIv2Token = @"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJJdUFiSnZvZXpwZTFFWUM2ZVhRRUoyd0QwSm5MOE5IZSIsInNjb3BlcyI6eyJ1c2VycyI6eyJhY3Rpb25zIjpbInVwZGF0ZSJdfX0sImlhdCI6MTQ2ODA0NjQ1MSwianRpIjoiOTA5MmJiMzBiNTJhNWYxNDQ5NjQ0NjNiZjY3ODM3OWUifQ.YS24m0ywZo2B6Y2Wfu11zzudLHU-25XK3DIiSZPVldA";


@interface ViewController ()

@property (copy, nonatomic) NSString *userId;

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *userIdLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameMetadataTextField;
@property (weak, nonatomic) IBOutlet UITextField *countryMetadataTextField;
@property (weak, nonatomic) IBOutlet UITextView *metadataText;

- (IBAction)clickOpenLockUIButton:(id)sender;
- (IBAction)clickUpdateUserdataButton:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickOpenLockUIButton:(id)sender {
    A0LockViewController *controller = [[A0Lock sharedLock] newLockViewController];
    controller.closable = YES;
    controller.onAuthenticationBlock = ^(A0UserProfile *profile, A0Token *token) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.usernameLabel.text = profile.name;
            self.emailLabel.text = profile.email;
            self.userIdLabel.text = profile.userId;
            self.metadataText.text = [NSString stringWithFormat:@"%@", profile.userMetadata];
        });
        self.userId = profile.userId;
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)clickUpdateUserdataButton:(id)sender {
    //we need to add Auth0 APIv2 token to header of responce
    NSString *token = [NSString stringWithFormat:@"Bearer %@", kAuth0APIv2Token];
    NSDictionary *headers = @{ @"content-type": @"application/json",
                               @"Authorization": token};
    
    if (!self.userId) {
        [self showMessage:@"Please login first"];
        return;
    }
    
    //create a new metadata dictionary
    //if these items are exist they will be rewritten
    NSDictionary *body = @{ @"user_metadata" : @{
                            @"name": self.nameMetadataTextField.text,
                            @"country" : self.countryMetadataTextField.text
                            }
                            };
    
    NSError *error;
    NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:body
                                                           options:0
                                                             error:&error];
    
    NSString *userId = [self.userId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    
    //create PATCH request for creating/updating user metadata
    //APIv2 https://auth0.com/docs/api/management/v2#!/Users/patch_users_by_id
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
                                                        [self showMessage:[NSString stringWithFormat:@"%@", error]];
                                                    } else {
                                                        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                                                        NSLog(@"%@", dict);
                                                        if (dict[@"user_metadata"]) {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                self.metadataText.text = [NSString stringWithFormat:@"%@",dict[@"user_metadata"]];
                                                            });
                                                        }
                                                    }
                                                }];
    [dataTask resume];
    

}

- (void)showMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Auth0" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

@end
