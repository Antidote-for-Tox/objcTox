source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

pod 'toxcore-ios', '~> 0.1.5'
pod 'CocoaLumberjack', '~> 1.9.2'
pod 'Realm', '~> 0.92.1'

target :objcToxTests do
    pod 'OCMock', '~> 3.1.2'
    pod 'Realm/Headers', '~> 0.92.1'
end

target :objcToxDemo do
    pod 'Masonry', '~> 0.6.1'
    pod 'BlocksKit', '~> 2.2.5'
end

post_install do |installer|
    puts 'Patching libopus'
    %x(git apply libopus.patch)
end
