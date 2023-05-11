//
//  Model_iaAPI.swift
//  MyMovies
//
//  Created by Raman Kozar on 07/05/2023.
//

import Foundation
import iaAPI

// Structures for the application
//
struct ResponseModel {
    
    var identifier: String
    var archiveTitle: String
    var name: String
    var size: String
    var format: ArchiveFileFormat
    var length: String
    
}

struct ModelForApplication {
    
    var nameOfTheMovie: String
    var linkToTheMovie: String
    var linkToThePreview: String
    
}

// Main methods for working with iaAPI functionality
//
class API_Methods {
    
    let pageAddress: String = "https://archive.org/metadata/"
    
    func getAllTheLinksToTheFiles(_ movieFiles: [ResponseModel], completion: @escaping (ModelForApplication) -> ()) {
        
        if !movieFiles.isEmpty {
            
            for movieElement in movieFiles {
                
                let url = URL(string: pageAddress + movieElement.identifier)
                
                guard let url = url else {
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                    do {
                        
                        var currentImageName: String = ""
                        var currentMovieName: String = ""
                        var currentMainLink_d1: String = ""
                        var currentMainLink_dir: String = ""
                        
                        if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                            
                            if let mainLink_d1 = json["d1"] as? String {
                                currentMainLink_d1 = mainLink_d1
                            }
                            
                            if let mainLink_dir = json["dir"] as? String {
                                currentMainLink_dir = mainLink_dir
                            }
                            
                            let jsonFiles = json["files"] as! [AnyObject]
                            
                            var imageHadFound: Bool = false
                            var movieHadFound: Bool = false
                            
                            for jsonFile in jsonFiles {
                                
                                if !imageHadFound || !movieHadFound {
                                
                                    let currentFormat = jsonFile["format"] as! String
                                    let currentName = jsonFile["name"] as! String
                                    
                                    if currentFormat == "Item Tile" && self.stringIsThePicture(currentName) {
                                        currentImageName = currentName
                                        imageHadFound = true
                                    }
                                    
                                    if currentFormat == "h.264" && self.stringIsTheMovie(currentName) {
                                        currentMovieName = currentName
                                        movieHadFound = true
                                    }
                                    
                                }
                                
                            }
                            
                            if !currentMainLink_d1.isEmpty && !currentMainLink_dir.isEmpty && movieHadFound {
                                
                                var currentImageToAdd: String = ""
                                var currentMovieToAdd: String = ""
                                
                                if imageHadFound {
                                    let tempImageName = currentMainLink_d1 + currentMainLink_dir + "/" + currentImageName
                                    currentImageToAdd = "https://" + tempImageName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                                } else {
                                    currentImageToAdd = "Empty"
                                }
                                
                                let tempMovieName = currentMainLink_d1 + currentMainLink_dir + "/" + currentMovieName
                                currentMovieToAdd = "https://" + tempMovieName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                                
                                let newFinalModel = ModelForApplication(nameOfTheMovie: currentMovieName, linkToTheMovie: currentMovieToAdd, linkToThePreview: currentImageToAdd)
                                
                                completion(newFinalModel)
                                
                            }
                            
                        }
                        
                    } catch let error as NSError {
                        print("Failed to load: \(error.localizedDescription)")
                    }
                    
                }.resume()
                
            }
            
        }
    
    }
    
    func convertSearchStringToDesiredFormat(_ inputString: String) -> String {
    
        let trimmedInputString = inputString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInputStringArray = trimmedInputString.components(separatedBy: " ")
        
        var finalString: String = ""
        let countOfWordsInString = trimmedInputStringArray.count
        
        for (indexArray, elementArray) in trimmedInputStringArray.enumerated() {
            
            if indexArray != countOfWordsInString - 1 {
                finalString += elementArray + "+"
            } else {
                finalString += elementArray
            }
            
        }
        
        finalString += "&and%5B%5D"
        
        return finalString
        
    }
    
    // Checking methods
    
    // is the string-check method
    //
    private func stringIsThePicture(_ nameFromJson: String) -> Bool {
        return nameFromJson.contains(".jpg") || nameFromJson.contains(".png") || nameFromJson.contains(".jpeg")
    }
    
    // is the movie-check method
    //
    private func stringIsTheMovie(_ nameFromJson: String) -> Bool {
        return nameFromJson.contains(".mp4")
    }
    
}
