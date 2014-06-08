BCOTabController
================

Gunosy風のタブを付けるコンテナビューコントローラ。  
This is the container view controller, which shows tabs on the top of the screen like Gunosy!

## Useage

1. Copy "BCOTabController" folder in "TabControllerSample" to your project.
2. Write code in AppDelegate.m like below. 

````smalltalk
// create 10 view controllers.
NSMutableArray *viewControllersBuf = @[].mutableCopy;
for (int i = 0; i < 10; i++) {
    BCOViewController *vc = [[BCOViewController alloc] init];
    [viewControllersBuf addObject:vc];
}
    
// create BCOTabController instance and set the created view controllers.
self.tabController = [[BCOTabController alloc] init];
_tabController.viewControllers = [viewControllersBuf copy];

self.window.rootViewController = _tabController;
````

## Opiton
You can change tab colors (background, highlighted background, textc olor, highlighted text color)
