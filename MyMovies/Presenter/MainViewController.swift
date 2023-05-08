//
//  MainViewController.swift
//  MyMovies
//
//  Created by Raman Kozar on 07/05/2023.
//

import UIKit
import AVKit
import iaAPI

class MainViewController: UIViewController {

    let service = ArchiveService()
    let mediaTypes: [ArchiveMediaType] = [.movies]
    var mediaType: Int = 0
    var page: Int = 1
    var rows = 100
    var numberOfResults = 0
    var items: [ArchiveMetaData] = []
    var movieFiles = [ResponseModel]()
    var dataForApplication = [ModelForApplication]()
    
    @IBOutlet weak var mainSearchField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MainTableViewCell", bundle: nil), forCellReuseIdentifier: "MainCell")
        tableView.separatorStyle = .none
        
    }
    
    @IBAction func updateInfoButton(_ sender: Any) {
        
        movieFiles.removeAll()
        items.removeAll()
        dataForApplication.removeAll()
        
        let myQuery: String = "david+guetta&and%5B%5D"
        
        getArchive(myQuery)
        
    }
    
    func getAllTheLinksToTheFiles(completion: @escaping (ModelForApplication) -> ()) {
        
        if !movieFiles.isEmpty {
            
            for movieElement in movieFiles {
                
                let url = URL(string: "https://archive.org/metadata/\(movieElement.identifier)")!
                
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
    
    func getArchive(_ myQuery: String) {
        
        Task {
            await getArchiveAsync(myQuery)
            getAllTheLinksToTheFiles(completion: { newFinalModel in
                self.addNewData(newFinalModel)
            })
        }
        
    }
    
    func addNewData(_ newFinalModel: ModelForApplication) {
        
        DispatchQueue.main.async {
            self.dataForApplication.append(newFinalModel)
            self.tableView.reloadData()
        }
        
    }
    
    func getArchiveAsync(_ query: String) async {
       
        do {

            let format_h264HD: ArchiveFileFormat = .h264HD
            let format_h264: ArchiveFileFormat = .h264
            
            let searchMediaType: ArchiveMediaType = mediaTypes[mediaType]
            let data_h264 = try await service.searchAsync(query: query, mediaTypes: [searchMediaType], rows: rows, page: page, format: format_h264)
            
            let data_h264HD = try await service.searchAsync(query: query, mediaTypes: [searchMediaType], rows: rows, page: page, format: format_h264HD)
            
            for curData in data_h264.response.docs {
                if curData.mediatype == .movies {
                    items.append(curData)
                }
            }
            
            for curData in data_h264HD.response.docs {
                if curData.mediatype == .movies {
                    items.append(curData)
                }
            }
                    
            numberOfResults = items.count
            
            for curDoc in items {

                do {
                    
                    let doc = try await service.getArchiveAsync(with: curDoc.identifier!)
                    
                    for docData in doc.files {
                        if docData.format == .h264 || docData.format == .h264HD {
                            
                            guard let identifier = docData.identifier else {
                                return
                            }
                            
                            guard let archiveTitle = docData.archiveTitle else {
                                return
                            }
                            
                            guard let name = docData.name else {
                                return
                            }
                            
                            guard let size = docData.size else {
                                return
                            }
                            
                            guard let format = docData.format else {
                                return
                            }
                            
                            guard let length = docData.length else {
                                return
                            }
                            
                            let newFile = ResponseModel(identifier: identifier, archiveTitle: archiveTitle, name: name, size: size, format: format, length: length)
                            
                            movieFiles.append(newFile)
                            
                        }
                    }
                    

                } catch {
                    print(error)
                }

            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }
    
    func stringIsThePicture(_ nameFromJson: String) -> Bool {
        return nameFromJson.contains(".jpg") || nameFromJson.contains(".png") || nameFromJson.contains(".jpeg")
    }
    
    func stringIsTheMovie(_ nameFromJson: String) -> Bool {
        return nameFromJson.contains(".mp4")
    }
    
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataForApplication.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as? MainTableViewCell else {
            return UITableViewCell()
        }
        
        let urlToImg = URL(string: dataForApplication[indexPath.row].linkToThePreview)!
        cell.loadInfoCell(urlToImg, dataForApplication[indexPath.row].nameOfTheMovie)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let verticalPadding: CGFloat = 8
        
        let maskLayer = CALayer()
        
        maskLayer.cornerRadius = 20
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: 0, dy: verticalPadding / 2)
        cell.layer.mask = maskLayer
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let myURL = URL(string: dataForApplication[indexPath.row].linkToTheMovie)!
        
        let player = AVPlayer(url: myURL)
        let vc = AVPlayerViewController()
        vc.player = player

        present(vc, animated: true) {
            vc.player?.play()
        }
        
    }
    
}
