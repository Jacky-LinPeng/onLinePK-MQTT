//
//  LOTView.swift
//  lottie-oc
//
//  Created by 刘立超 on 2020/2/3.
//  Copyright © 2020 刘立超. All rights reserved.
//
import Foundation
import UIKit
import Lottie
import YYCache

/// An Objective-C compatible wrapper around Lottie's Animation class.
/// Use in tandem with CompatibleAnimationView when using Lottie in Objective-C
public final class LOTAnimation: NSObject {
    
    let filepath: String
    var useCache: Bool = true
    fileprivate var animation: Animation? {
        if useCache {
            return Animation.filepath(filepath, animationCache: LRUAnimationCache.sharedCache)
        } else {
            return Animation.filepath(filepath)
        }
    }

    @objc init(bundle: String, forder: String) {
        if let bundlePath = Bundle.main.path(forResource: bundle, ofType: "bundle") {
            self.filepath = bundlePath + "/" + forder + "/data.json"
        } else {
            self.filepath = forder + "/data.json"
        }
    }
    
    @objc init(filepath: String) {
      self.filepath = filepath
      super.init()
    }
}

/// An Objective-C compatible wrapper around Lottie's AnimationView.
@objc public final class PWLOTAnimationView: UIView {
    @objc static func animationWithFilePath(_ path: String) -> PWLOTAnimationView {
        return PWLOTAnimationView(compatibleAnimation: LOTAnimation(filepath: path))
    }
    
    @objc public static func animationNamed(_ name: String) -> PWLOTAnimationView {
        #if PWSocialKit
            //podspec内需要设置PWResourceHelper为public
            let bundlePath = PWResourceHelper.getResouceLottieFilePath(name)
            return PWLOTAnimationView(compatibleAnimation: LOTAnimation(filepath: bundlePath))
        #else
            let bundlePath = getFilePath(name)
            return PWLOTAnimationView(compatibleAnimation: LOTAnimation(filepath: bundlePath))
        #endif
    }
    
    @objc public static func getFilePath(_ name: String) -> String{
        var bundlePath = Bundle.main.bundlePath
        bundlePath = bundlePath + "/" + name + ".json"
        return bundlePath
    }
    
    @objc public func setAnimationNamed(_ name: String) {
        self.filePath = PWLOTAnimationView.getFilePath(name)
    }
    
    @objc convenience init(bundle: String, forder: String) {
        let lot = LOTAnimation(bundle: bundle, forder: forder)
        self.init(compatibleAnimation: lot)
    }
    
    fileprivate init(compatibleAnimation: LOTAnimation) {
        let imageProvider = PWLOTCustomImageProvider(folderPath: (compatibleAnimation.filepath as NSString).deletingLastPathComponent)
        animationView = AnimationView(animation: compatibleAnimation.animation, imageProvider: imageProvider)
        self.compatibleAnimation = compatibleAnimation
        super.init(frame: .zero)
        commonInit()
    }

    @objc override init(frame: CGRect) {
        animationView = AnimationView()
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

  // MARK: Public
    @objc var useCache: Bool = true
    
    var folderPath: (bundle: String, name: String)? {
        didSet {
            guard let path = folderPath else { return }
            self.compatibleAnimation = LOTAnimation(bundle: path.bundle, forder: path.name)
        }
    }
    
    @objc var filePath: String? {
        didSet {
            guard let path = filePath else { return }
            self.compatibleAnimation = LOTAnimation(filepath: path)
        }
    }
    
    @objc public override var frame: CGRect {
        didSet {
            animationView.frame = self.bounds
        }
    }

    private var compatibleAnimation: LOTAnimation? {
        didSet {
            if let filepath = compatibleAnimation?.filepath {
                animationView.imageProvider = PWLOTCustomImageProvider(folderPath: (filepath as NSString).deletingLastPathComponent)
            }
            compatibleAnimation?.useCache = self.useCache
            animationView.animation = compatibleAnimation?.animation
        }
    }

    /// Returns `true` if the animation is currently playing.
    @objc public var isAnimationPlaying: Bool {
        return animationView.isAnimationPlaying
    }
    
    @objc public var loopAnimation: Bool = false {
        didSet {
            animationView.loopMode = loopAnimation ? .loop : .playOnce
        }
    }
    
    @objc var loopAnimationCount: CGFloat = 0 {
        didSet {
            animationView.loopMode = loopAnimationCount == -1 ? .loop : .repeat(Float(loopAnimationCount))
        }
    }

    @objc public override var contentMode: UIView.ContentMode {
        set { animationView.contentMode = newValue }
        get { return animationView.contentMode }
    }

    @objc var shouldRasterizeWhenIdle: Bool {
        set { animationView.shouldRasterizeWhenIdle = newValue }
        get { return animationView.shouldRasterizeWhenIdle }
    }

    @objc var currentProgress: CGFloat {
        set { animationView.currentProgress = newValue }
        get { return animationView.currentProgress }
    }

    @objc var currentTime: TimeInterval {
        set { animationView.currentTime = newValue }
        get { return animationView.currentTime }
    }

    @objc var currentFrame: CGFloat {
        set { animationView.currentFrame = newValue }
        get { return animationView.currentFrame }
    }

    @objc var realtimeAnimationFrame: CGFloat {
        return animationView.realtimeAnimationFrame
    }

    @objc var realtimeAnimationProgress: CGFloat {
        return animationView.realtimeAnimationProgress
    }

    @objc var animationSpeed: CGFloat {
        set { animationView.animationSpeed = newValue }
        get { return animationView.animationSpeed }
    }

    @objc var respectAnimationFrameRate: Bool {
        set { animationView.respectAnimationFrameRate = newValue }
        get { return animationView.respectAnimationFrameRate }
    }
    
    @objc public func play() {
        play(completion: nil)
    }

    @objc public func play(completion: ((Bool) -> Void)?) {
        reseted = false
        animationView.play(completion: completion)
    }
    
    @objc public func play(toProgress: CGFloat, withCompletion: ((Bool) -> Void)? = nil) {
        reseted = false
        animationView.play(toProgress: toProgress, completion: withCompletion)
    }

    @objc public func play(fromProgress: CGFloat, toProgress: CGFloat, withCompletion: ((Bool) -> Void)? = nil) {
        reseted = false
        animationView.play(fromProgress: fromProgress, toProgress: toProgress, loopMode: nil, completion: withCompletion)
    }

    @objc public func play(fromFrame: CGFloat, toFrame: CGFloat, completion: ((Bool) -> Void)? = nil) {
        reseted = false
        animationView.play(fromFrame: fromFrame, toFrame: toFrame, loopMode: nil, completion: completion)
    }

    @objc func play(fromMarker: String, toMarker: String, completion: ((Bool) -> Void)? = nil) {
        reseted = false
        animationView.play(fromMarker: fromMarker, toMarker: toMarker, completion: completion)
    }

    @objc public func stop() {
        animationView.stop()
    }
    
    @objc public func clear() {
        animationView.animation = nil
    }
    
    private var reseted = true
    @objc func reset() {
        guard !reseted else {
            if currentProgress != 0 {
                animationView.currentProgress = 0
            }
            return
        }
        filePath = self.compatibleAnimation?.filepath
        reseted = true
    }

    @objc func pause() {
        animationView.pause()
    }

    @objc func reloadImages() {
        animationView.reloadImages()
    }

    @objc func forceDisplayUpdate() {
        animationView.forceDisplayUpdate()
    }

    @objc func getValue(for keypath: CompatibleAnimationKeypath, atFrame: CGFloat) -> Any? {
        return animationView.getValue(for: keypath.animationKeypath, atFrame: atFrame)
    }

    @objc func logHierarchyKeypaths() {
        animationView.logHierarchyKeypaths()
    }

//  @objc
//  public func setColorValue(_ color: UIColor, forKeypath keypath: CompatibleAnimationKeypath)
//  {
//    var red: CGFloat = 0
//    var green: CGFloat = 0
//    var blue: CGFloat = 0
//    var alpha: CGFloat = 0
//    // TODO: Fix color spaces
//    let colorspace = CGColorSpaceCreateDeviceRGB()
//
//    let convertedColor = color.cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil)
//
//    if let components = convertedColor?.components, components.count == 4 {
//      red = components[0]
//      green = components[1]
//      blue = components[2]
//      alpha = components[3]
//    } else {
//      color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
//    }
//
//    let valueProvider = ColorValueProvider(Color(r: Double(red), g: Double(green), b: Double(blue), a: Double(alpha)))
//    animationView.setValueProvider(valueProvider, keypath: keypath.animationKeypath)
//  }
//
//  @objc
//  public func getColorValue(for keypath: CompatibleAnimationKeypath, atFrame: CGFloat) -> UIColor?
//  {
//    let value = animationView.getValue(for: keypath.animationKeypath, atFrame: atFrame)
//    guard let colorValue = value as? Color else {
//        return nil;
//    }
//
//    return UIColor(red: CGFloat(colorValue.r), green: CGFloat(colorValue.g), blue: CGFloat(colorValue.b), alpha: CGFloat(colorValue.a))
//  }

    @objc func addSubview(_ subview: AnimationSubview, forLayerAt keypath: CompatibleAnimationKeypath) {
        animationView.addSubview(subview, forLayerAt: keypath.animationKeypath)
    }

    @objc func convert(rect: CGRect, toLayerAt keypath: CompatibleAnimationKeypath?) -> CGRect {
        return animationView.convert(rect, toLayerAt: keypath?.animationKeypath) ?? .zero
    }

    @objc func convert(point: CGPoint, toLayerAt keypath: CompatibleAnimationKeypath?) -> CGPoint {
        return animationView.convert(point, toLayerAt: keypath?.animationKeypath) ?? .zero
    }

    @objc func progressTime(forMarker named: String) -> CGFloat {
        return animationView.progressTime(forMarker: named) ?? 0
    }

    @objc func frameTime(forMarker named: String) -> CGFloat {
        return animationView.frameTime(forMarker: named) ?? 0
    }

    // MARK: Private

    private let animationView: AnimationView

    private func commonInit() {
        //translatesAutoresizingMaskIntoConstraints = false
        animationView.backgroundBehavior = .pauseAndRestore
        setUpViews()
    }

    private func setUpViews() {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animationView)
        animationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        animationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        animationView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

private var kppLottieUrl = "pp.lottie.url"
private let lottieYYCache: YYDiskCache = {
    let lottieYYCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/pp.lottie.cache"
    let cache = YYDiskCache(path: lottieYYCachePath)!
    cache.countLimit = 1024*1024*5
    return cache
}()

extension AnimationView {
    
    func setUrl(_ url: String?, callback:((Error?) -> Void)? = nil) {
        _setUrl(url, callback: callback)
        lottieYYCache.countLimit = 1024 * 1024 * 10
    }
    
    private(set) var lottieUrl: String? {
        get {
            return objc_getAssociatedObject(self, &kppLottieUrl) as? String
        }
        set {
            objc_setAssociatedObject(self, &kppLottieUrl, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    private func _setUrl(_ url: String?, callback:((Error?) -> Void)? = nil) {
        lottieUrl = url
        //TODO:linpeng
        guard let urlStr = url, let urlValue = URL(string: urlStr) else {
//            callback?(NSError.make(msg: "url错误"))
            callback?(NSError.init(domain: "url error", code: -1, userInfo: [:]))
            return
        }
        let key = ""//(urlStr as NSString).md5() ?? ""
        
        if let animation = LRUAnimationCache.sharedCache.animation(forKey: key) {
            self.animation = animation
            callback?(nil)
            return
            
        }
        
        DispatchQueue.global().async { [weak self] in
            if let data = lottieYYCache.object(forKey: key) as? Data, let animation = try? JSONDecoder().decode(Animation.self, from: data) {
                guard let sself = self, sself.lottieUrl == url else { return }
                DispatchQueue.main.async {
                    self?.animation = animation
                    callback?(nil)
                }
            } else {
                let task = URLSession.shared.dataTask(with: urlValue) { [weak self] (data, response, error) in
                    guard let sself = self, sself.lottieUrl == url else { return }
                    if let data = data, let animation = try? JSONDecoder().decode(Animation.self, from: data)  {
                        LRUAnimationCache.sharedCache.setAnimation(animation, forKey: key)
                        lottieYYCache.setObject(data as NSCoding, forKey: key)
                        if sself.lottieUrl == url {
                            DispatchQueue.main.async {
                                self?.animation = animation
                                callback?(nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            callback?(error)
                        }
                    }
                }
                task.resume()
            }
        }
    }
}
