source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

pod 'toxcore-ios', '~> 0.1.3'
pod 'CocoaLumberjack', '~> 1.9.2'
pod 'Realm', '~> 0.91.3'

target :objcToxTests do
    pod 'OCMock', '~> 3.1.2'
end

post_install do |installer|
    puts 'Patching libopus'
    %x(git apply libopus.patch)
end
