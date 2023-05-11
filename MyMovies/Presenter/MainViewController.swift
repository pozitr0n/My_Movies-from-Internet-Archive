//
//  MainViewController.swift
//  MyMovies
//
//  Created by Raman Kozar on 07/05/2023.
//

import UIKit
import AVKit
import iaAPI

// Main presenter for every application
//
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
        
        setupUI()
        
    }
    
    // Search video button
    //
    @IBAction func updateInfoButton(_ sender: Any) {
        
        removeAllTheBufferTables()
        
        // for example, "tiesto"
        let tempQuery = mainSearchField.text
        guard let myQuery = tempQuery else {
            return
        }
        
        if !myQuery.isEmpty {
            
            let myFinalQuery = API_Methods().convertSearchStringToDesiredFormat(myQuery)
            getArchive(myFinalQuery)
            
        } else {
            tableView.reloadData()
        }
        
        DispatchQueue.main.async {
            self.mainSearchField.resignFirstResponder()
        }
        
    }
    
    // Method for getting all the results. Using await - first step is getting information,
    // second step - parcing and presenting them on the view
    private func getArchive(_ myQuery: String) {
        
        Task {
            
            await getArchiveAsync(myQuery)
            
            API_Methods().getAllTheLinksToTheFiles(movieFiles, completion: { newFinalModel in
                self.addNewData(newFinalModel)
            })
            
        }
        
    }
    
    // Method for async getting information using iaAPI functionality
    //
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
    
    // Adding new information row
    //
    private func addNewData(_ newFinalModel: ModelForApplication) {
        
        DispatchQueue.main.async {
            self.dataForApplication.append(newFinalModel)
            self.tableView.reloadData()
        }
        
    }
    
    // Method for setting up and configuring UI
    //
    private func setupUI() {
     
        tableView.register(UINib(nibName: MainTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: MainTableViewCell.identifier)
        tableView.separatorStyle = .none
        
        mainSearchField.clearButtonMode = .whileEditing
        
    }
    
    // Technical method for removing all the info from the cache tables
    //
    private func removeAllTheBufferTables() {
     
        movieFiles.removeAll()
        items.removeAll()
        dataForApplication.removeAll()
        
    }
    
}

// MainViewController-extension for table view
//
extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataForApplication.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainTableViewCell.identifier, for: indexPath) as? MainTableViewCell else {
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
        
        let playerController = AVPlayer(url: myURL)
        let avPlayerViewController = AVPlayerViewController()
        avPlayerViewController.player = playerController

        present(avPlayerViewController, animated: true) {
            avPlayerViewController.player?.play()
        }
        
    }
    
}

// MainViewController-extension for text view
//
extension MainViewController: UITextFieldDelegate {
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
}
