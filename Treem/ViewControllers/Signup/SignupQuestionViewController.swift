//
//  SignupQuestionViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/12/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SignupQuestionViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var signupQuestionTextView: UITextView!
    @IBOutlet weak var signupQuestionTextViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var changeQuestionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var helpTextView: UITextView!
    @IBOutlet weak var helpTextViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var answersTableView: UITableView!
    @IBOutlet weak var answersTableViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func changeQuestionTouchUpInside(sender: AnyObject) {
        self.loadQuestion()
    }
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController         = ErrorViewController.getStoryboardInstance()
    
    private var currentQuestionID   : String?                   = nil
    private var currentAnswers      : [SignupQuestionAnswer]    = []

    private var timer       : NSTimer!
    private var isTimerDone : Bool = true
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // keep view hidden until loading mask present
        self.view.hidden = true
        
        self.answersTableView.delegate      = self
        self.answersTableView.dataSource    = self
        self.answersTableView.layoutMargins = UIEdgeInsetsZero
        self.answersTableView.rowHeight     = 48
        
        // remove padding/margin from textview
        self.signupQuestionTextView.removeEdgeInsets()
        self.helpTextView.removeEdgeInsets()
        
        // load captcha if in debug mode, or in release mode and not a simulator
        #if DEBUG
            self.loadQuestion()
        #else
            if !Device.sharedInstance.isSimulator() {
                self.loadQuestion()
            }
            else {
                self.view.hidden = false
                self.errorViewController.showSimulatorNotSupportedView(self.view)
            }
        #endif

        // adjust positioning of change button depending on screen size
        if Device.sharedInstance.isResolutionSmallerThaniPhone5() {
            self.changeQuestionTopConstraint.constant = 4
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // adjust text view height layout based on text content
        self.helpTextViewHeightConstraint.constant = self.helpTextView.sizeThatFits(self.helpTextView.bounds.size).height
        
        // load translated text into textview (xcode bug, uitextview not translated directly)
        self.helpTextView.setTextSafely(Localization.sharedInstance.getLocalizedString("MIM-g2-6R2.text", table: "SignupQuestion"))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // start timer after view appears
        if self.isTimerDone {
            self.isTimerDone    = false
            self.timer          = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "timerDone", userInfo: nil, repeats: true)
        }
    }
    
    private func loadQuestion() {
        // load the challenge question
        self.loadingMaskViewController.queueLoadingMask(
            self.parentViewController?.view ?? self.view,
            showCompletion: {
                
                TreemAuthorizationService.sharedInstance.getChallengeQuestion(
                    self.currentQuestionID,
                    failureCodesHandled: [
                        TreemServiceResponseCode.InternalServerError,
                        TreemServiceResponseCode.NetworkError,
                        TreemServiceResponseCode.LockedOut,
                        TreemServiceResponseCode.InvalidConsumerKey,
                        TreemServiceResponseCode.InvalidSignature,
                        TreemServiceResponseCode.DisabledConsumerKey
                    ],
                    success: {
                        data in
                        // keep view hidden until loading mask present
                        self.view.hidden = false
                        
                        let signupQuestionResponse = SignupQuestionResponse(json: data)
                        
                        self.currentQuestionID  = signupQuestionResponse.id
                        
                        self.currentAnswers = signupQuestionResponse.answers ?? []
                            
                        // reload
                        self.answersTableView.reloadData()
                        
                        // adjust table view based on number/size of answers
                        self.answersTableViewHeightConstraint.constant = self.answersTableView.contentSize.height
                        
                        // adjust question text view based on question text
                        self.signupQuestionTextView.text                        = signupQuestionResponse.question
                        self.signupQuestionTextViewHeightConstraint.constant    = self.signupQuestionTextView.sizeThatFits(self.signupQuestionTextView.bounds.size).height

                        self.loadingMaskViewController.cancelLoadingMask(nil)
                    },
                    failure: {
                        error, wasHandled in
                        
                        // keep view hidden until loading mask present
                        self.view.hidden = false
                        
                        self.loadingMaskViewController.cancelLoadingMask({
                            if !wasHandled {
                                let recover = {
                                    // reload question if not
                                    self.loadQuestion()
                                }
                                
                                if error == TreemServiceResponseCode.NetworkError {
                                    self.errorViewController.showNoNetworkView(self.view, recover: recover)
                                }
                                else if error == TreemServiceResponseCode.InternalServerError {
                                    self.errorViewController.showGeneralErrorView(self.view, recover: recover)
                                }
                                else if error == TreemServiceResponseCode.LockedOut {
                                    self.errorViewController.showLockedOutView(self.view, recover: recover)
                                }
                                else if (error == TreemServiceResponseCode.InvalidSignature || error == TreemServiceResponseCode.InvalidConsumerKey) {
                                    self.errorViewController.showInvalidDeviceView(self.view, recover: recover)
                                }
                                else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                                    self.errorViewController.showDeviceDisabledView(self.view, recover: recover)
                                }
                            }
                            else {
                                CustomAlertViews.showGeneralErrorAlertView()
                            }
                        })
                    }
                )
            }
        )
    }
    
    func timerDone () {
        self.isTimerDone = true
        self.timer.invalidate()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentAnswers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell    = tableView.dequeueReusableCellWithIdentifier("SignupAnswerCell") as! HiddenIDTableCell
        
        if(self.currentAnswers.indices.contains(indexPath.row)){
            let answer  = self.currentAnswers[indexPath.row]
            
            cell.sid                        = answer.id
            cell.textLabel?.text            = answer.answerText
            cell.layoutMargins              = UIEdgeInsetsZero
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.isTimerDone {
            if let questionID = self.currentQuestionID {
                if(self.currentAnswers.indices.contains(indexPath.row)){
                    let answer = self.currentAnswers[indexPath.row]
                    
                    self.loadingMaskViewController.queueLoadingMask(
                        self.view,
                        showCompletion: {
                            TreemAuthorizationService.sharedInstance.authorizeApp(
                                questionID,
                                answerID: answer.id,
                                success: {
                                    data in
                                    self.loadingMaskViewController.cancelLoadingMask({
                                        if (SignupAuthorizeAppResponse(json: data) != nil) {
                                            // transition to phone view
                                            self.performSegueWithIdentifier("signupPhoneSegue", sender: self)
                                        }
                                        else {
                                            CustomAlertViews.showGeneralErrorAlertView()
                                        }
                                    })
                                },
                                failure: {
                                    error, wasHandled in

                                    self.loadingMaskViewController.cancelLoadingMask({
                                        if !wasHandled {
                                            if error == TreemServiceResponseCode.GenericResponseCode2 {
                                                // question expired
                                                CustomAlertViews.showCustomAlertView(
                                                    title: Localization.sharedInstance.getLocalizedString("question_expired_title", table: "SignupQuestion"),
                                                    message: Localization.sharedInstance.getLocalizedString("question_expired_message", table: "SignupQuestion"),
                                                    willDismiss: self.loadQuestion
                                                )
                                            }
                                            else if error == TreemServiceResponseCode.GenericResponseCode3 {
                                                // invalid answer
                                                CustomAlertViews.showCustomAlertView(
                                                    title: Localization.sharedInstance.getLocalizedString("incorrect_answer_title", table: "SignupQuestion"),
                                                    message: Localization.sharedInstance.getLocalizedString("incorrect_answer_message", table: "SignupQuestion"),
                                                    willDismiss: self.loadQuestion
                                                )
                                            }
                                        }
                                        else {
                                            CustomAlertViews.showGeneralErrorAlertView()
                                            
                                            // deselect row just in case
                                            tableView.deselectRowAtIndexPath(indexPath, animated: false)
                                        }
                                    })
                                }
                            )
                        }
                    )
                }
            }
        }
        else {
            // deselect row just in case
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
}
