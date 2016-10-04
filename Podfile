source 'https://github.com/CocoaPods/Specs.git'

# ignore all warnings from all pods
inhibit_all_warnings!

def common_pods
    pod 'toxcore', :git => 'https://github.com/Antidote-for-Tox/toxcore.git', :commit => 'c3bd97b4f8650e405e5f6d295c4c4fd4b4fef64f'
    pod 'CocoaLumberjack', '~> 1.9.2'
    pod 'Realm', '1.0.1'
    pod 'TPCircularBuffer', '~> 0.0.1'
end

def demo_pods
    pod 'Masonry', '~> 0.6.1'
    pod 'BlocksKit', '~> 2.2.5'
end

def test_pods
    pod 'OCMock', '3.1.2'
end


target :iOSDemo do
    platform :ios, '7.0'
    common_pods
    demo_pods
end

target :iOSDemoTests do
    platform :ios, '7.0'
    common_pods
    test_pods
end

target :OSXDemo do
    platform :osx, '10.9'
    common_pods
    demo_pods
end

target :OSXDemoTests do
    platform :osx, '10.9'
    common_pods
    test_pods
end
