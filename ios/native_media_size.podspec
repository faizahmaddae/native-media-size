Pod::Spec.new do |s|
  s.name             = 'native_media_size'
  s.version          = '0.1.0'
  s.summary          = 'Query file sizes from the OS media database without file I/O.'
  s.description      = <<-DESC
Query file sizes for photo/video assets directly from the OS media database
(PHAssetResource on iOS) without copying files to the app sandbox.
                       DESC
  s.homepage         = 'https://github.com/faizdae/native_media_size'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Faiz Dae' => 'faizdae@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
