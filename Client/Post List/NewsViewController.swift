//
//  NewsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import libHN

class NewsViewController : UITableViewController, UISplitViewControllerDelegate, PostTitleViewDelegate, SFSafariViewControllerDelegate, SFSafariViewControllerPreviewActionItemsDelegate, UIViewControllerPreviewingDelegate {
    
    var posts: [HNPost] = [HNPost]()
    fileprivate var collapseDetailViewController = true
    fileprivate var peekedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForPreviewing(with: self, sourceView: tableView)
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension // auto cell size magic

        refreshControl!.backgroundColor = Theme.backgroundGreyColour
        refreshControl!.tintColor = Theme.orangeColour
        refreshControl!.addTarget(self, action: #selector(NewsViewController.loadPosts), for: UIControlEvents.valueChanged)
        
        splitViewController!.delegate = self
        
        Theme.setNavigationBarBackground(navigationController!.navigationBar)
        loadPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
        rz_smoothlyDeselectRows(tableView: tableView)
    }
    
    func test(completion: GetPostsCompletion) {
        
    }
    
    func loadPosts() {
        if !refreshControl!.isRefreshing {
            refreshControl!.beginRefreshing()
        }
        
        HNManager.shared().loadPosts(with: .top) { posts, nextPageIdentifier in
            if let downcastedArray = posts as? [HNPost] {
                self.posts = downcastedArray
                self.tableView.reloadData()
                self.refreshControl!.endRefreshing()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        let post = posts[indexPath.row]
        cell.postTitleView.post = post
        cell.postTitleView.delegate = self
        
        // TODO: if not default post type, show ycombinator domain instead in metadataLabel
        // cant do it currently as Type is reserved keyword which libHN uses
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
        var viewController = storyboard!.instantiateViewController(withIdentifier: "PostViewNavigationController")
        let commentsViewController = (viewController as! UINavigationController).viewControllers.first as! CommentsViewController
        
        let post = posts[indexPath.row]
        commentsViewController.post = post
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            // for iPhone we only want to push the view controller not navigation controller
            viewController = commentsViewController
        }
        
        showDetailViewController(viewController, sender: self)
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
    
    // MARK: - PostCellDelegate
    
    func getSafariViewController(_ URL: String) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: Foundation.URL(string: URL)!)
        safariViewController.previewActionItemsDelegate = self
        return safariViewController
    }
    
    func didPressLinkButton(_ post: HNPost) {
        self.navigationController?.present(getSafariViewController(post.urlString), animated: true, completion: nil)
        UIApplication.shared.statusBarStyle = .default
    }
    
    // MARK: - UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRow(at: location) {
            peekedIndexPath = indexPath
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            let post = posts[indexPath.row]
            return getSafariViewController(post.urlString)
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        present(viewControllerToCommit, animated: true, completion: nil)
    }
    
    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem] {
        let indexPath = self.peekedIndexPath!
        let post = posts[indexPath.row]
        let commentsPreviewActionTitle = post.commentCount > 0 ? "View \(post.commentCount) comments" : "View comments"
        
        let viewCommentsPreviewAction = UIPreviewAction(title: commentsPreviewActionTitle, style: .default) {
            [unowned self, indexPath = indexPath] (action, viewController) -> Void in
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.tableView(self.tableView, didSelectRowAt: indexPath)
        }
        return [viewCommentsPreviewAction]
    }
}
