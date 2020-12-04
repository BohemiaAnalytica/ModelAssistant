//
//  BasicTableViewController.swift
//  iOS_Example
//
//  Created by Seyed Samad Gholamzadeh on 9/8/18.
//  Copyright © 2018 Seyed Samad Gholamzadeh. All rights reserved.
//

/*
Abstract:
In this file we prepare BasicTableViewController to use ModelAssistant, for interacting with model.
*/

import UIKit
import ModelAssistant

class BasicTableViewController: UITableViewController, ImageDownloaderDelegate {
	
	
	var imageDownloadsInProgress: [Int : ImageDownloader<Contact>]!  // the set of IconDownloader objects for each app
	
	var assistant: ModelAssistant<Contact>!
	var resourceFileName: String = "PhoneBook"
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.imageDownloadsInProgress = [:]
		
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

		self.configureModelAssistant(sectionKey: nil)
		self.fetchEntities()
	}
	
	/// This method creates an instance of ModelAssistant with the given sectionKey
	func configureModelAssistant(sectionKey: String?) {
		self.assistant = ModelAssistant<Contact>(sectionKey: sectionKey)
	}
	
	func fetchEntities(completion: (() -> Void)? = nil) {
		let url = Bundle.main.url(forResource: resourceFileName, withExtension: "json")!
		let contacts: [Contact] = JsonService.getEntities(fromURL: url)
		self.assistant.fetch(contacts) { [weak self] in
            		guard let self = self else {
                		return
            		}
			completion?()
			self.tableView.reloadData()
		}
	}
	

	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return self.assistant.numberOfSections
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return self.assistant.numberOfEntites(at: section)
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		self.configure(cell, at: indexPath)
		
		return cell
	}
	
	func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
		
		let entity = self.assistant[indexPath]
		// Configure the cell...
		cell.textLabel?.text =  entity?.fullName
		
		// Only load cached images; defer new downloads until scrolling ends
		if entity?.image == nil
		{
			if (self.tableView.isDragging == false && self.tableView.isDecelerating == false)
			{
				self.startIconDownload(entity!)
			}
			
			// if a download is deferred or in progress, return a placeholder image
			cell.imageView?.image = UIImage(named: "Placeholder")
		}
		else
		{
			cell.imageView?.image = entity?.image
		}
		cell.imageView?.contentMode = .center
		
	}
	
	override func update(_ cell: UITableViewCell, at indexPath: IndexPath) {
		self.configure(cell, at: indexPath)
	}

	
	//MARK: - Table cell image support
	
	func startIconDownload(_ entity: Contact) {
		let uniqueValue = entity.uniqueValue
		var imageDownloader: ImageDownloader! = imageDownloadsInProgress[uniqueValue]
		if imageDownloader == nil {
			imageDownloader = ImageDownloader(from: entity.imageURL, forEntity: entity)
			imageDownloader.delegate = self
			imageDownloadsInProgress[uniqueValue] = imageDownloader
			imageDownloader.startDownload()
		}
	}
	
	// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
	func loadImagesForOnscreenRows() {
		if !self.assistant.isEmpty {
			let visiblePaths = self.tableView.indexPathsForVisibleRows ?? []
			for indexPath in visiblePaths {
				guard let entity = self.assistant[indexPath] else { return }
				if entity.image == nil // avoid the app icon download if the app already has an icon
				{
					self.startIconDownload(entity)
				}
			}
		}
	}
	
	// called by our ImageDownloader when an icon is ready to be displayed
	func downloaded<T>(_ image: UIImage?, forEntity entity: T) {

		self.assistant.update(entity as! Contact, mutate: { (contact) in
			contact.image = image
		}, completion: nil)

		// Remove the IconDownloader from the in progress list.
		// This will result in it being deallocated.
		self.imageDownloadsInProgress.removeValue(forKey: (entity as! Contact).uniqueValue)
	}
	
	//MARK: - Deferred image loading (UIScrollViewDelegate)
	
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate {
			self.loadImagesForOnscreenRows()
		}
	}
	
	override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		self.loadImagesForOnscreenRows()
	}
		
}
