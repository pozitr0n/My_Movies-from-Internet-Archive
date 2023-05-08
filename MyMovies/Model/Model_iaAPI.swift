//
//  Model_iaAPI.swift
//  MyMovies
//
//  Created by Raman Kozar on 07/05/2023.
//

import Foundation
import iaAPI

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
