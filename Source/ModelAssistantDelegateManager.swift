//
//  ControllerProtocol.swift
//  iOS_Example
//
//  Created by Seyed Samad Gholamzadeh on 9/2/18.
//  Copyright © 2018 Seyed Samad Gholamzadeh. All rights reserved.

/*
Abstract:
	In this file we created a mechanism to use `performBatchUpdates(_:completion:)` method for implementing ModelAssistantDelegate methods
*/

import Foundation

/**
	The CollectionController protocol is an abstract of methods that each collection view needs for interacting with its datasource. This protocol makes ModelAssistantDelegateManager class independent of ViewControllers.
	Any ViewController that uses ModelAssistantDelegateManager to implement ModelAssistantDelegate methods, must adopt this protocol.
*/
public protocol MACollectionController: class {

	func maInsert(at indexPaths: [IndexPath])

	func maDelete(at indexPaths: [IndexPath])

	func maMove(at indexPath: IndexPath, to newIndexPath: IndexPath)

	func maUpdate(at indexPath: IndexPath)

	func maInsertSections(_ sections: IndexSet)

	func maDeleteSections(_ sections: IndexSet)

	func maMoveSection(_ section: Int, toSection newSection: Int)

	func maReloadSections(_ sections: IndexSet)

	func maPerformBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?)
}


/**
The ModelAssistantDelegateManager class uses `performBatchUpdates(_:completion:)` to implement ModelAssistantDelegate methods. The way it works is that, we collect all the notifications sending to ModelAssistantDelegate as BlockOperation in an array. Then, when modelAssistantDidChangeContent() called, we execute these blocks into the `performBatchUpdates(_:completion:)` updates block.
*/
class ModelAssistantDelegateManager: ModelAssistantDelegate {

	var blockOperations: [Foundation.BlockOperation] = []

	unowned var controller: MACollectionController

	init(controller: MACollectionController) {
		self.controller = controller
	}


	func addToBlockOperation(_ operation: @escaping () -> Void) {

		let operation = Foundation.BlockOperation {
			operation()
		}

		blockOperations.append(operation)
	}

	public func modelAssistantWillChangeContent() {

	}


	public func modelAssistant<Entity>(didChange entities: [Entity], at indexPaths: [IndexPath]?, for type: ModelAssistantChangeType, newIndexPaths: [IndexPath]?) where Entity : MAEntity, Entity : Hashable {
		switch type {

		case .insert:

			self.addToBlockOperation { [weak self] in
				guard let `self` = self else { return }
				if let newIndexPaths = newIndexPaths {
					self.controller.maInsert(at: newIndexPaths)
				}
			}

		case .update:

			if let indexPaths = indexPaths {
				for indexPath in indexPaths {
					self.controller.maUpdate(at: indexPath)
				}
			}

		case .move:

			self.addToBlockOperation { [weak self] in
				guard let `self` = self else { return }

				if let indexPaths = indexPaths {
					for i in 0..<indexPaths.count {
						let indexPath = indexPaths[i]
						let newIndexPath = newIndexPaths![i]
						self.controller.maMove(at: indexPath, to: newIndexPath)
					}
				}

			}

		case .delete:

			self.addToBlockOperation { [weak self] in
				guard let `self` = self else { return }
				if let indexPaths = indexPaths {
					self.controller.maDelete(at: indexPaths)
				}
			}

		}
	}
	func modelAssistant<Entity>(didChange sectionInfos: [SectionInfo<Entity>], atSectionIndexes sectionIndexes: [Int]?, for type: ModelAssistantChangeType, newSectionIndexes: [Int]?) where Entity : MAEntity, Entity : Hashable {
		switch type {
		case .insert:

			self.addToBlockOperation { [weak self] in
				guard let `self` = self else { return }
				if let newIndexes = newSectionIndexes {
					self.controller.maInsertSections(IndexSet(newIndexes))
				}
			}

		case .update:

			self.addToBlockOperation { [weak self] in
				guard let `self` = self else { return }
				if let indexes = sectionIndexes {
					self.controller.maReloadSections(IndexSet(indexes))
				}
			}

		case .move:

			self.addToBlockOperation { [weak self] in
				guard let `self` = self else { return }
				if let indexes = sectionIndexes, let newIndexes = newSectionIndexes {

					for i in indexes {
						let oldIndex = indexes[i]
						let newIndex = newIndexes[i]
						self.controller.maMoveSection(oldIndex, toSection: newIndex)
					}

				}
			}

		case .delete:

			self.addToBlockOperation { [weak self] in
				guard let `self` = self else { return }
				if let indexes = sectionIndexes {
					self.controller.maDeleteSections(IndexSet(indexes))
				}
			}

		}
	}

	public func modelAssistantDidChangeContent() {
		self.controller.maPerformBatchUpdates({
			for operation: Foundation.BlockOperation in self.blockOperations {

				// We directly call `start()` method of BlockOperations instead of adding them to a queue, so they execute in the main thread.
				operation.start()
			}

		}) { (finished) in
			self.blockOperations.removeAll(keepingCapacity: false)
		}
	}

	public func modelAssistant(sectionIndexTitleForSectionName sectionName: String) -> String? {
		return String(Array(sectionName)[0]).uppercased()
	}

}




