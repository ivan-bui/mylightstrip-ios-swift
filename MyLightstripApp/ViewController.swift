//
//  ViewController.swift
//  MyLightstripApp
//
//  Created by Ivan Bui on 2019-05-14.
//  Copyright © 2019 Ivan Bui. All rights reserved.
//

import UIKit
import CoreData
import AFNetworking
import ChromaColorPicker


struct ColorRGB {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
}

class ViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, ChromaColorPickerDelegate {

    @IBOutlet weak var colorPicker: ChromaColorPicker!
    @IBOutlet weak var brightnessSlider: ChromaShadeSlider!
    @IBOutlet weak var sceneCollectionView: UICollectionView!
    
    let cellReuseIdentifier = "SceneCell"
    let leftAndRightPaddings: CGFloat = 50.0
    let numberOfItemsPerRow: CGFloat = 2.0
    let collectionViewCellHeight: CGFloat = 75.0
    var timer: Timer? = nil
    var baseUrl: String
    var scenes: [NSManagedObject] = []
    
    required init?(coder aDecoder: NSCoder) {
        baseUrl = Bundle.main.object(forInfoDictionaryKey: "SERVER_BASE_URL") as! String
        super.init(coder: aDecoder)
        self.retrieveFromCoreData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneCollectionView.dataSource = self
        sceneCollectionView.delegate = self
        colorPicker.delegate = self

        initCollectionViewLayout()
        initNavigationBar()
        initColorPicker()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func initCollectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5.0, left: 0, bottom: 5.0, right: 0)
        layout.itemSize = CGSize(width: (sceneCollectionView!.frame.width - leftAndRightPaddings) / numberOfItemsPerRow, height: collectionViewCellHeight)
        layout.minimumInteritemSpacing = 3.0
        sceneCollectionView!.collectionViewLayout = layout
    }
    
    func initNavigationBar() {
        self.navigationController!.navigationBar.barStyle = .black
        self.navigationController!.navigationBar.isTranslucent = true
        self.navigationItem.title = "MyLightstrip"
        initLightstripSwitch()
    }
    
    func initLightstripSwitch() {
        let lightstripSwitch = UISwitch(frame: .zero)
        lightstripSwitch.isOn = true
        lightstripSwitch.addTarget(self, action: #selector(toggledSwitch), for: UIControl.Event.valueChanged)
        let switchDisplay = UIBarButtonItem(customView: lightstripSwitch)
        self.navigationItem.rightBarButtonItem = switchDisplay
    }

    @objc func toggledSwitch(_ mySwitch: UISwitch) {
        var brightness: CGFloat = 0.0
        if mySwitch.isOn {
            brightness = brightnessSlider.currentValue
        }
        requestLightstripChange(urlPath: "brightness", r: 0, g: 0, b: 0, brightness: brightness)
    }
    
    func initColorPicker() {
        colorPicker.stroke = 15
        colorPicker.hexLabel.textColor = UIColor.white
        brightnessSlider.autoresizingMask = .flexibleWidth
    }
    
    
    // MARK: - SceneCollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return scenes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! SceneCollectionViewCell
        let scene = scenes[indexPath.item]
        let image = scene.value(forKey: "imageName") as! String
        let name = scene.value(forKey: "displayName") as! String

        cell.imageView.image = UIImage(named: image)
        cell.label.text = name
        cell.layer.cornerRadius = 12.0
        cell.imageView.layer.masksToBounds = true
        cell.imageView.layer.cornerRadius = 8.0
        cell.colourR = scene.value(forKey: "colourR") as! CGFloat
        cell.colourG = scene.value(forKey: "colourG") as! CGFloat
        cell.colourB = scene.value(forKey: "colourB") as! CGFloat
        cell.brightness = scene.value(forKey: "brightness") as! CGFloat

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! SceneCollectionViewCell
        let sceneColor = UIColor(displayP3Red: cell.colourR, green: cell.colourG, blue: cell.colourB, alpha: 1.0)
        cell.changeScene()
        colorPicker.adjustToColor(sceneColor)
        brightnessSlider.currentValue = cell.brightness
        brightnessSlider.updateHandleLocation()
    }
    
    
    // MARK: - CoreData methods
    
    func retrieveFromCoreData() {
        scenes = []
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Scenes")
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            for data in result as! [NSManagedObject] {
                scenes.append(data)
           }
        } catch {
            print("Failed retrieving")
        }
    }
    
    func saveNewScene(name: String, valuesR: CGFloat, G: CGFloat, B: CGFloat, brightness: CGFloat) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let sceneEntity = NSEntityDescription.entity(forEntityName: "Scenes", in: managedContext)!
        
        //TODO - select image from device
        let newScene = NSManagedObject(entity: sceneEntity, insertInto: managedContext)
        newScene.setValue("default", forKey: "imageName")
        newScene.setValue(name, forKey: "displayName")
        newScene.setValue(brightness, forKey: "brightness")
        newScene.setValue(valuesR, forKey: "colourR")
        newScene.setValue(G, forKey: "colourG")
        newScene.setValue(B, forKey: "colourB")
        
        do {
            try managedContext.save()
            retrieveFromCoreData()
            sceneCollectionView.reloadData()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    
    // MARK: - ChromaColorPicker methods

    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        let alert = UIAlertController(title: "Save Scene", message: "Enter scene name", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (action) -> Void in
            let text = alert!.textFields![0].text!
            let color = self.getRGBFromColorPicker()
            let brightness = self.getBrightnessSliderValue()
            self.saveNewScene(name: text, valuesR: color.red, G: color.green, B: color.blue, brightness: brightness)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
            alert .dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func colorHasChanged(_ sender: Any) {
        let color = getRGBFromColorPicker()
        let brightness = getBrightnessSliderValue()
        debounce(seconds: 0.2) {
            self.requestLightstripChange(urlPath: "colour/rgb", r: color.red, g: color.green, b: color.blue, brightness: brightness)
        }
    }
    
    @IBAction func brightnessHasChanged(_ sender: Any) {
        let brightness = getBrightnessSliderValue()
        requestLightstripChange(urlPath: "brightness", r: 0, g: 0, b: 0, brightness:brightness)
    }
    
    func debounce(seconds: TimeInterval, function: @escaping () -> Swift.Void ) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            function()
        })
    }
    
    func getRGBFromColorPicker() -> ColorRGB {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        (colorPicker.currentColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorRGB(red: r, green: g, blue: b)
    }
    
    func getBrightnessSliderValue() -> CGFloat {
        var brightness1 : CGFloat = 0
        var brightness2 : CGFloat = 0
        var brightness3 : CGFloat = 0
        var brightnessAlpha : CGFloat = 0
        (brightnessSlider.currentColor).getRed(&brightness1, green: &brightness2, blue: &brightness3, alpha: &brightnessAlpha)
        return brightness1
    }
    
    func requestLightstripChange(urlPath: String, r: CGFloat, g: CGFloat, b: CGFloat, brightness: CGFloat) {
        let params = [
            "r": r,
            "g": g,
            "b": b,
            "brightness": brightness
        ]
        let manager = AFHTTPSessionManager()
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        manager.post(baseUrl + urlPath, parameters: params, progress: nil, success: { (sessionTask, respose) in
            if let dict = respose as? Dictionary<String,Any> {
                print(dict)
            } else {
            }
        }, failure: { (sessionTask, error) in
            print(error)
        })
//        manager.get(baseUrl + urlPath, parameters: parameterDictionary, progress: nil, success: { (sessionTask, respose) in
//            if let dict = respose as? Dictionary<String,Any> {
//                print(dict)
//            } else {
//            }
//        }, failure: { (sessionTask, error) in
//            print(error)
//        })
    }
}
