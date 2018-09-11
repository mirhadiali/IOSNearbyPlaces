

import UIKit
import CoreLocation
import Alamofire

class NearbyPlacesController {
    static func getCategories() -> [QCategory] {
        let list:[QCategory] = ["Bakery", "Doctor", "School", "Taxi_stand", "Hair_care", "Restaurant", "Pharmacy", "Atm", "Gym", "Store", "Spa"]
        return list
    }
        
    static let searchApiHost = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    static let googlePhotosHost = "https://maps.googleapis.com/maps/api/place/photo"
    static let googlePlaceDetailsHost = "https://maps.googleapis.com/maps/api/place/details/json"
    
    static func getNearbyPlaces(by category:String, coordinates:CLLocationCoordinate2D, radius:Int, token: String?, completion: @escaping (QNearbyPlacesResponse?) -> Void) {
    
        var params : [String : Any]
        
        if let t = token {
            params = [
                "key" : AppDelegate.googlePlacesAPIKey,
                "pagetoken" : t,
            ]
        } else {
            params = [
                "key" : AppDelegate.googlePlacesAPIKey,
                "radius" : radius,
                "location" : "\(coordinates.latitude),\(coordinates.longitude)",
                "type" : category.lowercased()
            ]
        }
        
        // request
        Alamofire.request(searchApiHost, parameters: params, encoding: URLEncoding(destination: .queryString)).responseJSON { response in
            //print(response)
            let response = QNearbyPlacesResponse.init(dic: response.result.value as? [String: Any])
            completion(response)
        }
    }
    
    static func getPlaceDetails(place:QPlace, completion: @escaping (QPlace) -> Void) {
        print("-------------------------")
        guard place.details == nil else {
            completion(place)
            return
        }
        
        var params : [String : Any]
        params = [
            "key" : AppDelegate.googlePlacesAPIKey,
            "placeid" : place.placeId,
            "fields" : "rating,formatted_phone_number,website",
        ]
        
        Alamofire.request(googlePlaceDetailsHost, parameters: params, encoding: URLEncoding(destination: .queryString)).responseJSON { response in
            print(response)
            print(place.placeId)
            let value = response.result.value as? [String : Any]
            place.details = (value)?["result"] as? [String : Any]
            completion(place)
        }
    }
    
    static func googlePhotoURL(photoReference:String, maxWidth:Int) -> URL? {
        return URL.init(string: "\(googlePhotosHost)?maxwidth=\(maxWidth)&key=\(AppDelegate.googlePlacesAPIKey)&photoreference=\(photoReference)")
    }
}


struct QNearbyPlacesResponse {
    var nextPageToken: String?
    var status: String  = "NOK"
    var places: [QPlace]?
    
    init?(dic:[String : Any]?) {
        nextPageToken = dic?["next_page_token"] as? String
        
        if let status = dic?["status"] as? String {
            self.status = status
        }
        
        if let results = dic?["results"] as? [[String : Any]]{
            var places = [QPlace]()
            for place in results {
                places.append(QPlace.init(placeInfo: place))
            }
            self.places = places
        }
    }
    
    func canLoadMore() -> Bool {
        if status == "OK" && nextPageToken != nil && nextPageToken?.count ?? 0 > 0 {
            return true
        }
        return false
    }
}
