//
//  YPLibrary+LibraryChange.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension YPLibraryVC: PHPhotoLibraryChangeObserver {
    func registerForLibraryChanges() {
        PHPhotoLibrary.shared().register(self)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            let fetchResult = self.mediaManager.fetchResult!
            let collectionChanges = changeInstance.changeDetails(for: fetchResult)
            if collectionChanges != nil {
                self.mediaManager.fetchResult = collectionChanges!.fetchResultAfterChanges
                let collectionView = self.v.collectionView!
                if !collectionChanges!.hasIncrementalChanges || collectionChanges!.hasMoves {
                    collectionView.reloadData()
                } else {
                    let selection = self.selection
                    collectionView.performBatchUpdates({
                        let removedIndexes = collectionChanges!.removedIndexes
                        if (removedIndexes?.count ?? 0) != 0 {
                            collectionView.deleteItems(at: removedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                        let insertedIndexes = collectionChanges!.insertedIndexes
                        if (insertedIndexes?.count ?? 0) != 0 {
                            collectionView.insertItems(at: insertedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                        }
                    }, completion: { [weak self] finished in
                        if finished {
                            let changedIndexes = collectionChanges!.changedIndexes
                            if (changedIndexes?.count ?? 0) != 0 {
                                collectionView.reloadItems(at: changedIndexes!.aapl_indexPathsFromIndexesWithSection(0))
                            }
                        }
                        //reset index to 0 when selected item changed to fix can't fetch asset from photo library
                        guard let `self` = self else { return }
                        let removedIndexItems = collectionChanges?.removedIndexes?.aapl_indexPathsFromIndexesWithSection(0).map({ $0.item }) ?? []
                        let changedIndexItems = collectionChanges?.changedIndexes?.aapl_indexPathsFromIndexesWithSection(0).map({ $0.item }) ?? []
                        let allItems = removedIndexItems + changedIndexItems
//                            let selectionIndexes = selection.map { $0.index }
//                            if selectionIndexes.contains(where: { allItems.contains($0)}) {
                        if !allItems.isEmpty {
                            self.currentlySelectedIndex = 0
                            self.selection.removeAll()
                            self.refreshMediaRequest()
                        }

                    })
                }
                self.mediaManager.resetCachedAssets()
            }
        }
    }
}
