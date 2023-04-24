//
//  ViewController.swift
//  SeeFood
//
//  Created by Ali KINU on 8.04.2023.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage




class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label: UILabel!
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://www.mediawiki.org/w/api.php"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary // .camera
        imagePicker.allowsEditing = false // true olursa crop yapabilirsin bide
    }
    
    
    @IBAction func cameraTabbed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true)  //camera
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage { //userPickedImage == UIImage -> photo taken
           
            guard let ciimage = CIImage(image : userPickedImage) else {fatalError("//UIImage COULDNT CONVERT TO CIImage(coreImage)")}
            
            detect(image:ciimage)
            
            imageView.image = userPickedImage //kamerada cekilen foto ana ekrana aktarıyor(imageView)
        }
        imagePicker.dismiss(animated: true) //when you tab on use photo--done with the photo(use image)
    }
    
    
    func detect (image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: Inceptionv3.urlOfModelInThisBundle)) else {
            fatalError("can't load ML model")}//(VN=VİSİON FRAMEWORK)CONTAINER hazırlanıyor / try? -> it can be nil model--- try catch ypmdm byuzdn
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else{fatalError("VNClassificationObservation faild PROCESS")}
            print(results)
            
            DispatchQueue.main.async {
                
                if let firstResult = results.first {  // if firstResult.identifier.contains("something")/
                    self.navigationItem.title = firstResult.identifier.capitalized
//                    self.label.text = firstResult.identifier.capitalized
                    self.requestInfo(objectName: firstResult.identifier.capitalized)
                    print("------\(firstResult.identifier.capitalized)")
                }
            }
       
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])  //handler : taken foto is being set to make request ^^
        } catch {
            print(error)
        }
        
    }
  
    func requestInfo(objectName : String ) {
            let objectNameParameters : [String:String] = [

                        "format" : "json",
                        "action" : "query",
                        "prop" : "extracts|pageimages",
                        "exintro" : "",
                        "explaintext" : "",
                        "titles" : objectName,
                        "indexpageids" : "",
                        "redirects" : "1",
                        "pithumsize": "500"

                    ]
            Alamofire.request(wikipediaURL, method: .get, parameters: objectNameParameters).responseJSON { response in
                if response.result.isSuccess {
                    print(response)
                    DispatchQueue.main.async {
                        let objectJSON: JSON = JSON(response.result.value!)
                        let pageid = objectJSON["query"]["pageids"][0].stringValue
                        let objectDescription = objectJSON["query"]["pages"][pageid]["extract"].stringValue
                        print(objectDescription)
                        self.label.text = objectDescription
//                        let objectImageURL = objectJSON["query"]["pages"][pageid]["thumnail"]["source"].stringValue
//                        self.imageView.sd_setImage(with: URL(string: objectImageURL)) //doesn't work! deal with it later on back here
                    }



                }

            }
        }

    
}

