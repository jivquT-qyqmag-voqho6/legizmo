// Legizmo – Preferences/RootListController.m
// Main preferences UI using PreferenceLoader / PSListController

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface LGZRootListController : PSListController
@end

@implementation LGZRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"LegizmoPrefs" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Legizmo";

    // Version footer
    NSString *version = [[NSBundle bundleWithIdentifier:@"com.lunotech11.legizmo"] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"5.0";
    UILabel *footer = [[UILabel alloc] init];
    footer.text = [NSString stringWithFormat:@"Legizmo Moonstone v%@\nby lunotech11", version];
    footer.textAlignment = NSTextAlignmentCenter;
    footer.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    footer.textColor = [UIColor secondaryLabelColor];
    footer.numberOfLines = 0;
    footer.frame = CGRectMake(0, 0, self.view.bounds.size.width, 60);
    self.table.tableFooterView = footer;
}

// Called when the "Respring" cell is tapped
- (void)respring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Respring"
        message:@"Respring is required to apply Legizmo changes. Continue?"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        // Trigger respring via killall SpringBoard
        pid_t pid;
        const char *args[] = {"killall", "-9", "SpringBoard", NULL};
        posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
