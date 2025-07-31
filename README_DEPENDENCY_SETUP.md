# wBlockCoreService Dependency Setup

## Important: Configuring the wBlockCoreService Package

The Flutter wBlock plugin depends on the `wBlockCoreService` Swift package. To properly configure this dependency:

### For iOS

1. Navigate to `example/ios/` directory
2. Open or create the `Podfile`
3. Add the following before the `target` block:

```ruby
# Add the wBlockCoreService pod source
pod 'wBlockCoreService', :git => 'https://github.com/amosogra/wBlockCoreService_Package.git', :tag => '1.0.0'
```

### For macOS

1. Navigate to `example/macos/` directory
2. Open or create the `Podfile`
3. Add the following before the `target` block:

```ruby
# Add the wBlockCoreService pod source
pod 'wBlockCoreService', :git => 'https://github.com/amosogra/wBlockCoreService_Package.git', :tag => '1.0.0'
```

### After Adding the Dependency

Run the following commands:

```bash
# For iOS
cd example/ios
pod install

# For macOS
cd example/macos
pod install
```

## Note

The `wBlockCoreService` folder in the plugin's ios/macos directories is only for reference and understanding the API. The actual implementation will come from the GitHub package specified above.

Once the plugin is ready for production, the local `wBlockCoreService` folders should be deleted as they are only placeholders for development reference.
