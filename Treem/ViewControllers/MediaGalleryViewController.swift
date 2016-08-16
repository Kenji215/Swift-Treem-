//
//  MediaGalleryViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/22/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class MediaGalleryViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var userID                              : Int? = nil
    var userIsSelf                          : Bool = false
    
    private var contentItems                : [ContentItemDelegate]? = nil

    // layout properties
    private var numOfColumns                : CGFloat = 3
    private var cellSpacing                 : CGFloat = 3
    private var cellSize                    : Int = 100     // this get's overriden at run time depending on size of screen
    
    private lazy var errorViewController         = ErrorViewController.getStoryboardInstance()
    private var loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    let downloadOperations = DownloadContentOperations()
    
    
    static func getStoryboardInstance() -> MediaGalleryViewController {
        return UIStoryboard(name: "MediaGallery", bundle: nil).instantiateInitialViewController() as! MediaGalleryViewController
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // figure out how large each cell is
        self.cellSize = Int((UIScreen.mainScreen().bounds.width - ((self.numOfColumns - 1) * self.cellSpacing)) / self.numOfColumns)
        
        self.loadMediaGallery()
    }
    
    // ------------------- //
    // server calls
    // ------------------- //
    
    private func loadMediaGallery(){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            
            self.showLoadingMask()
            
            // get view size
            TreemFeedService.sharedInstance.getUserContentPosts(
                CurrentTreeSettings.sharedInstance.treeSession,
                page: 0,
                pageSize: 100,
                date: NSDate(),
                user_id: self.userID,
                success: {
                    data in
                    
                    self.contentItems = ContentItemUpload.loadContentItems(data)
                    
                    self.cancelLoadingMask({
                        
                        if(self.contentItems == nil){
                            self.showEmptyView()
                        }
                        else{
                            self.collectionView?.reloadData()
                        }
                    })

                },
                failure: {
                    error, wasHandled in
                    
                    self.cancelLoadingMask()
                }
            )
        }
    }
    
    // ------------------- //
    // helpers
    // ------------------- //
    
    private func showLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.queueLoadingMask(self.view, loadingViewAlpha: 1.0, showCompletion: completion)
        }
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.cancelLoadingMask(completion)
        }
    }

    private func fitImageToCell(cell: MediaGalleryCollectionViewCell, image: UIImage){

        let contextImage: UIImage = UIImage(CGImage: image.CGImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(self.cellSize)
        var cgheight: CGFloat = CGFloat(self.cellSize)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let newImage: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        
        cell.galleryImageView.image = newImage
    }
    
    private func showEmptyView() {
        self.errorViewController.showErrorMessageView(self.view, text: Localization.sharedInstance.getLocalizedString("no_images", table: "MediaGallery"))

        self.collectionView?.scrollEnabled        = false
        self.collectionView?.alwaysBounceVertical = false
    }
    
    // ------------------- //
    // form delegates
    // ------------------- //
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            return CGSize(width: self.cellSize, height: self.cellSize)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let items = self.contentItems{
            return items.count
        }
        else {
            return 0
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MediaGalleryCell", forIndexPath: indexPath) as! MediaGalleryCollectionViewCell
        
        cell.tag = indexPath.row
        
        if let items = self.contentItems {
            if (items.indices.contains(indexPath.row)){
                let item = items[indexPath.row]
                
                if let contentItem     = item as? ContentItemDownload {
                    let contentURL      = contentItem.contentURL
                    
                    // get avatar image
                    if let url = contentURL, downloader = DownloadContentOperation(url: url, cacheKey: contentItem.contentURLId) {
                        downloader.completionBlock = {
                            if let image = downloader.image where !downloader.cancelled {
                                // perform UI changes back on the main thread
                                dispatch_async(dispatch_get_main_queue(), {
                                    
                                    // check that the cell hasn't been reused
                                    if (cell.tag == indexPath.row) {

                                        // if cell in view then animate, otherwise add if in table but not visible
                                        if collectionView.visibleCells().contains(cell) {
                                            UIView.transitionWithView(
                                                cell.galleryImageView,
                                                duration: 0.1,
                                                options: UIViewAnimationOptions.TransitionCrossDissolve,
                                                animations: {
                                                    self.fitImageToCell(cell, image: image)
                                                },
                                                completion: nil
                                            )
                                        }
                                        else {
                                            self.fitImageToCell(cell, image: image)
                                        }
                                    }
                                })
                            }
                        }
                        self.downloadOperations.startDownload(indexPath, downloadContentOperation: downloader)
                    }
                }
            }
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if let items = self.contentItems {
            if (items.indices.contains(indexPath.row)){
                let item = items[indexPath.row]
                
                if let cType = item.contentType {
                    if(cType == .Video){
                        let vc = MediaVideoViewController.getStoryboardInstance()
                        
                        vc.contentId = item.contentID
                        
                        self.navigationController?.presentViewController(vc, animated: true, completion: nil)
                    }
                    else{
                        
                        let vc = MediaImageViewController.getStoryboardInstance()
                        
                        if let contentItem = item as? ContentItemDownload {
                            vc.contentUrl = contentItem.contentURL
                            vc.contentId = item.contentID
                            vc.contentOwner = self.userIsSelf
                            vc.deletedCallback = {
                                self.contentItems!.removeAtIndex(indexPath.row)
                                self.collectionView?.reloadData()
                            }
                        }
                        
                        self.navigationController?.presentViewController(vc, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
