//
//  TaskDetailViewController.swift
//  photo-scavenger-hunt
//
//  Created by Derrick Ng on 3/18/23.
//

import UIKit
import MapKit
import PhotosUI
import AVFoundation

class TaskDetailViewController: UIViewController {
    
    // elements at the beginning
    @IBOutlet weak var completedImageView: UIImageView!
    @IBOutlet weak var completedLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var attachPhotoButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    // Image View outlet
    @IBOutlet weak var imageView: UIImageView!
    // MapView outlet
    @IBOutlet weak var mapView: MKMapView!
    // ImageView + MapView Stack
    @IBOutlet weak var imageMapStackView: UIStackView!
    
    // Task var to contain passed-in data
    var task: Task!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register custom annotation view
        mapView.register(TaskAnnotationView.self, forAnnotationViewWithReuseIdentifier: TaskAnnotationView.identifier)

        // Set mapView delegate
        mapView.delegate = self

        // UI Candy
        mapView.layer.cornerRadius = 12
        
        // update UI and MapView
        updateUI()
        updateImageView()
        updateMapView()
    }
    
    /// Configure UI for the given task
    private func updateUI() {
        titleLabel.text = task.title

        let completedImage = UIImage(systemName: task.isComplete ? "circle.inset.filled" : "circle")

        // calling `withRenderingMode(.alwaysTemplate)` on an image allows for coloring the image via it's `tintColor` property.
        completedImageView.image = completedImage?.withRenderingMode(.alwaysTemplate)
        completedLabel.text = task.isComplete ? "Complete" : "Incomplete"

        let color: UIColor = task.isComplete ? .systemGreen : .systemPink
        completedImageView.tintColor = color
        completedLabel.textColor = color

        // use task.isComplete property to control the hidden status of Views and Buttons
        imageMapStackView.isHidden = !task.isComplete
//        mapView.isHidden = !task.isComplete
//        imageView.isHidden = !task.isComplete
        attachPhotoButton.isHidden = task.isComplete
        takePhotoButton.isHidden = task.isComplete
    }
    
    @IBAction func didTapAttachPhotoButton(_ sender: UIButton) {
        // If authorized, show photo picker, otherwise request authorization.
        // If authorization denied, show alert with option to go to settings to update authorization.
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            // Request photo library access
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                switch status {
                case .authorized:
                    // The user authorized access to their photo library
                    // show picker (on main thread)
                    DispatchQueue.main.async {
                        self?.presentImagePicker()
                    }
                default:
                    // show settings alert (on main thread)
                    DispatchQueue.main.async {
                        // Helper method to show settings alert
                        self?.presentGoToSettingsAlert()
                    }
                }
            }
        } else {
            // Show photo picker
            presentImagePicker()
        }
    }
    
    @IBAction func takePhotoButtonTapped(_ sender: UIButton) {
        presentCamera()
    }
    
    private func presentImagePicker() {
        
        // Create a configuration object
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())

        // Set the filter to only show images as options (i.e. no videos, etc.).
        config.filter = .images

        // Request the original file format. Fastest method as it avoids transcoding.
        config.preferredAssetRepresentationMode = .current

        // Only allow 1 image to be selected at a time.
        config.selectionLimit = 1

        // Instantiate a picker, passing in the configuration.
        let picker = PHPickerViewController(configuration: config)

        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self

        // Present the picker.
        present(picker, animated: true)
    }
    
    func updateImageView() {
        guard let image = task.image else { return }
        imageView.image = image
    }
    
    func updateMapView() {
        // Make sure the task has image location.
        guard let imageLocation = task.imageLocation else { return }

        // Get the coordinate from the image location. This is the latitude / longitude of the location.
        let coordinate = imageLocation.coordinate

        // Set the map view's region based on the coordinate of the image.
        // The span represents the maps's "zoom level". A smaller value yields a more "zoomed in" map area, while a larger value is more "zoomed out".
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)

        
        // Add an annotation to the map view based on image location.
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func checkCameraAuthorizationStatusAndRequestIfNeeded(completion: @escaping (Bool) -> Void) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .restricted, .denied:
            completion(false)
        case .authorized:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
}

// Conform to PHPickerViewControllerDelegate + implement required method(s)
extension TaskDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // This is where we'll get the picked image in the next step...
        // Dismiss the picker
        picker.dismiss(animated: true)

        // Get the selected image asset (we can grab the 1st item in the array since we only allowed a selection limit of 1)
        let result = results.first

        // Get image location
        // PHAsset contains metadata about an image or video (ex. location, size, etc.)
        guard let assetId = result?.assetIdentifier,
              let location = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject?.location else {
            return
        }
        // print to indicate the code works here ...
        print("📍 Image location coordinate: \(location.coordinate)")
        
        
        // Make sure we have a non-nil item provider
        guard let provider = result?.itemProvider,
              // Make sure the provider can load a UIImage
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

            // Handle any errors
            if let error = error {
              DispatchQueue.main.async { [weak self] in self?.showAlert(for:error) }
            
            }

            // Make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else { return }

            print("🌉 We have an image!")

            // UI updates should be done on main thread, hence the use of `DispatchQueue.main.async`
            DispatchQueue.main.async { [weak self] in

                // Set the picked image and location on the task
                self?.task.set(image, with: location)

                // Update the UI since we've updated the task
                self?.updateUI()
                
                // Update the image view since we now have an image
                self?.updateImageView()

                // Update the map view since we now have an image location
                self?.updateMapView()
            }
        }
    }
}

// Helper methods to present various alerts
extension TaskDetailViewController: MKMapViewDelegate {

    /// Presents an alert notifying user of photo library access requirement with an option to go to Settings in order to update status.
    func presentGoToSettingsAlert() {
        let alertController = UIAlertController (
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    /// Show an alert for the given error
    private func showAlert(for error: Error? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "\(error?.localizedDescription ?? "Please try again...")",
            preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)

        present(alertController, animated: true)
    }
}

// Conform to UIImagePickerControllerDelegate, UINavigationControllerDelegate + implement required method(s)
extension TaskDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Do something with the image, e.g., save it or set it to an image view
            
            // Save the image to the photo library
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
            // Display the image in the UIImageView
            imageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func presentCamera() {
        checkCameraAuthorizationStatusAndRequestIfNeeded { [weak self] granted in
            guard granted else {
                // Show an alert to inform the user that camera access is required
                print("Camera access is required!")
                return
            }

            DispatchQueue.main.async {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self
                    imagePickerController.sourceType = .camera
                    self?.present(imagePickerController, animated: true, completion: nil)
                } else {
                    // Show an alert to inform the user that the camera is not available
                    print("Camera is not available!")
                }
            }
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // Show an error alert
            let alertController = UIAlertController(title: "Error", message: "Could not save the photo: \(error.localizedDescription)", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            // Show a success alert or perform other tasks
            print("Took new photo with authorized camera. Successfully loaded!")
        }
    }
}

