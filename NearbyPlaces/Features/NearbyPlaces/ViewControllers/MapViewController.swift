
import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var bottomInfoView: UIView!
    
    var userLocation:CLLocationCoordinate2D?
    var places:[QPlace] = []
    var index:Int = -1
    
    var mapView:GMSMapView!
    var marker:GMSMarker?
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard index >= 0, places.count > 0 else {
            return
        }
        
        let place = places[index]
        let lat = place.location?.latitude ?? 1.310844
        let lng = place.location?.longitude ?? 103.866048
        
        // Google map view
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lng, zoom: 12.5)
        mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        self.containerView.addSubview(mapView)
//        24.948883, 67.064362
//        25.008627, 67.097680

        self.getPolylineRoute(from: CLLocationCoordinate2D(latitude: (userLocation?.latitude)!, longitude: (userLocation?.longitude)!), to: CLLocationCoordinate2D(latitude: lat, longitude: lng))
        
        // Add gesture
        addSwipeGesture()
        
        didSelect(place: place)
        if userLocation != nil {
            addMarkerAtCurrentLocation(userLocation!)
        }
    }
    
    // add gesture recognizer
    func addSwipeGesture() {
        let directions: [UISwipeGestureRecognizerDirection] = [.right, .left]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
            gesture.direction = direction
            self.bottomInfoView.addGestureRecognizer(gesture)
        }
    }
//    oygwCgoixKaAxAiA`By@rAiA`B_ArAcDzEiFvHyCpEsAzBBJ@JARGPKNOJMBM@_@IUYCGAGa@s@m@o@aJsHwMoKoHqGkIeHkIwGgCwBi@_@u@i@[OSEQAiAJyDP{DJsGLaCJuGNgKVaNf@iA@uCHuNT{BFiMZ{JViFHi@D_AXINWVWHM?[ESMMQIUuBDaKT_GNqDL_CD{HTkBDwIXmQ^_Pb@_MZaFH}HV[HONINOJSHS@_@GSMMSIWA[BYJULMFEBAF_@Dw@EqCImD_@qQMoHOsHKmDK{HWwIEiCGgE]}NGsAKuFI{DMqJUmSKmDKiBIy@{@wEIe@Kq@Gm@EsAKuFAaGWoM
    
    // Pass your source and destination coordinates in this method.
    func getPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D){
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&key=AIzaSyCcCG10K0F1qxiZxu1WQ5qRxFCHv4CeNo0")!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }else{
                do {
                    if let json : [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                        
                        if let routes = json["routes"] as? [Any] {
                            if let route = routes[0] as? [String:Any]{
                                if let overview_polyline = route["overview_polyline"] as? [String:Any]{
                                    if let polyString = overview_polyline["points"] as? String{
                                        //Call this method to draw path on map
                                        DispatchQueue.main.async {
                                            self.showPath(polyStr: polyString)
                                        }
                                    }
                                }
                            }
                        }
                    }

                }catch{
                    print("error in JSONSerialization")
                }
            }
        })
        task.resume()
    }
    
    func showPath(polyStr :String){
        let path = GMSPath(fromEncodedPath: polyStr)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        polyline.map = mapView // Your map view
    }
    
    func addMarkerAtCurrentLocation(_ userLocation: CLLocationCoordinate2D)  {
        let marker = GMSMarker()
        marker.position = userLocation
        marker.title = "Your location"
        marker.map = mapView
    }
    
    func didSelect(place:QPlace) {
        
        guard let coordinates = place.location else {
            return
        }
        
        // clear current marker
        marker?.map = nil
        
        // add marker
        marker = GMSMarker()
        marker?.position = coordinates
        marker?.title = place.name
        marker?.map = mapView
        mapView.selectedMarker = marker
        moveToMarker(marker!)
        
        // update bottom info panel view
        let desc = place.getDescription()
        descriptionLabel.text = desc.characters.count > 0 ? desc : "-"
        distanceLabel.text = "-"
        
        // update distance
        if userLocation != nil {
            let dist = distance(from: userLocation!, to: coordinates)
            distanceLabel.text = String.init(format: "Distance %.2f meters", dist)
        }
        
        title = place.name
    }
    
    func moveToMarker(_ marker: GMSMarker) {
        let camera = GMSCameraPosition.camera(withLatitude: marker.position.latitude,
                                              longitude: marker.position.longitude,
                                              zoom: 12.5)
        self.mapView.animate(to: camera)
    }
    
    // distance between two coordinates
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        
        guard index >= 0, places.count > 0 else {
            return
        }
        
        if sender.direction == .left {
            if index < places.count - 2 {
                index += 1
                didSelect(place: places[index])
            }
        } else if sender.direction == .right {
            if index > 1 {
                index -= 1
                didSelect(place: places[index])
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
