//
//  EquityRewardsViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/14/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import CorePlot
import SwiftyJSON

class EquityRewardsViewController: UIViewController, CPTRangePlotDataSource, CPTAxisDelegate, UITableViewDataSource {
    @IBOutlet weak var headerView           : UIView!
    @IBOutlet weak var graphView            : CPTGraphHostingView!
    @IBOutlet weak var topFriendsTableView  : UITableView!
	@IBOutlet weak var topFriendsTableHeight: NSLayoutConstraint!
    @IBOutlet weak var noFriends            : UILabel! //Placeholder text to display if user has no friends with equity yet. Hidden by default.

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var addFriendsButton: UIButton!

    @IBOutlet weak var myPoints: UILabel!
	@IBOutlet weak var myChange: StockTickerLabel!
    @IBOutlet weak var myPercentileText: UITextView!
	@IBOutlet weak var pointsHex: HexagonButton!

    @IBOutlet weak var equityPercentBar: UIView!

    @IBOutlet weak var equityRewardsSuccessZoneView: UIView!

	@IBOutlet weak var equityTickmark: UILabel!
	@IBOutlet weak var equityTickmarkLeading: NSLayoutConstraint!



    @IBAction func addFriendsButtonTouchUpInside(sender: AnyObject) {
        // show all members(friends)
        self.delegate?.showAddMembers()
    }
    
    private var graphData: [(NSTimeInterval, CGFloat)] = []
    private var friendsData : [Rollout] = []

	private var userPointsMax   : CGFloat = 0.0			//Keep track of the highest points on any given day with this, to make sure the y-axis scales enough

	private var intervalsToShow = 7
	private var dateFormatter = NSDateFormatter()
	private var calendar = NSCalendar.currentCalendar()
	private let numberFormatter = NSNumberFormatter()


    private var firstDateTime   : NSTimeInterval!
    private var lastDateTime    : NSTimeInterval!
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController         = ErrorViewController.getStoryboardInstance()
    
    private var hasLoadedRollout        : Bool = false
    private var hasLoadedTopFriends     : Bool = false
    private var hasLoadedHistoricalData : Bool = false

	private var percentileColors		: [UIColor] = [
		UIColor(red: 59/255.0, green: 49/255.0, blue: 84/255.0, alpha: 1)
		, UIColor(red: 138/255.0, green: 32/255.0, blue: 32/255.0, alpha: 1)
		, UIColor(red: 223/255.0, green: 93/255.0, blue: 48/255.0, alpha: 1)
		, UIColor(red: 232/255.0, green: 180/255.0, blue: 44/255.0, alpha: 1)
		, AppStyles.sharedInstance.tintColor
	]
	private var usersColor		: UIColor = AppStyles.sharedInstance.midGrayColor
    
    var delegate: EquityRewardsDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadingMaskViewController.queueLoadingMask(self.scrollView, loadingViewAlpha: 1.0, showCompletion: nil)
        
        // apply styles to sub header bar
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        self.view.backgroundColor = AppStyles.sharedInstance.subBarBackgroundColor

		self.addFriendsButton.setTitleColor(AppStyles.sharedInstance.tintColor, forState: .Normal)

        // remove excess padding from text view
        self.myPercentileText.textContainerInset = UIEdgeInsetsZero
        self.myPercentileText.textContainer.lineFragmentPadding = 0
        
        self.topFriendsTableView.dataSource = self
        self.topFriendsTableView.separatorColor = AppStyles.sharedInstance.dividerColor
        
        self.equityPercentBar.layer.borderColor = AppStyles.sharedInstance.midGrayColor.CGColor
        self.equityPercentBar.layer.borderWidth = 1.0

		for index in 0..<(self.equityPercentBar.subviews.count) {
			self.equityPercentBar.subviews[index].backgroundColor = self.percentileColors[index]
		}

		self.equityRewardsSuccessZoneView.backgroundColor = AppStyles.sharedInstance.tintColor


		self.dateFormatter.dateFormat = "M/d"
		self.numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle

		if let titleLabel = self.pointsHex.titleLabel {
			titleLabel.lineBreakMode                = NSLineBreakMode.ByWordWrapping
			titleLabel.textAlignment                = NSTextAlignment.Center
			titleLabel.numberOfLines                = 2
			titleLabel.adjustsFontSizeToFitWidth    = false
		}

		self.pointsHex.setTitleColor(AppStyles.sharedInstance.darkGrayColor, forState: .Normal)
		self.pointsHex.fillColor = UIColor.clearColor()
		self.pointsHex.backgroundColor = UIColor.clearColor()
		self.pointsHex.lineWidth = 5
		self.pointsHex.strokeColor = AppStyles.sharedInstance.midGrayColor
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.getUserRollout()
        self.getTopFriends()
        self.getHistoricalData()
    }
    
    static func getStoryboardInstance() -> EquityRewardsViewController {
        return UIStoryboard(name: "EquityRewards", bundle: nil).instantiateInitialViewController() as! EquityRewardsViewController
    }
    
    //Get the current user's total points, change today, and percentile.
    private func getUserRollout() {
        TreemEquityService.sharedInstance.getUserRollout(
            parameters: nil,
            failureCodesHandled: [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success: {
                (data:JSON) in

                //Parse the json data and turn it into a Rollout object to be used
                let user_rollout : Rollout = Rollout(json: data)

                //Total points
                self.myPoints.text = self.numberFormatter.stringFromNumber(user_rollout.points)! + " points"

                //Change today
				  self.myChange.points = user_rollout.change_today

                //Percentile of all users
                let user_percentile = user_rollout.percentile * 100

				UIView.performWithoutAnimation({
					let formattedPercent = String(format: "%.0f", user_percentile)
					self.pointsHex.setTitle(formattedPercent + "\n%", forState: .Normal)

					self.pointsHex.resizeSubstring(formattedPercent, size: 50)

					self.pointsHex.layoutIfNeeded()

					
				})

                let percentMessageKey: String
                
                // update rewards success colors
                if user_percentile < 80 {
                    // show lower percentage message
                    if user_percentile < 50 {
                        percentMessageKey = "myPercentLow"
                    }
                        // show higher percentage message but not yet in equity range
                    else {
                        percentMessageKey = "myPercentHighNonEquity"
                    }
                }
                else {
                    percentMessageKey = "myPercentHighEquity"
                }

				//Color the hex surrounding the percentile, as well as the numerical points value
				self.usersColor = self.getPercentileColor(user_rollout.percentile)
				self.myPoints.colorSubstring(self.numberFormatter.stringFromNumber(user_rollout.points)!, color: self.usersColor)
				self.pointsHex.strokeColor = self.usersColor


				self.equityTickmarkLeading.constant = (self.equityPercentBar.bounds.width * CGFloat(user_rollout.percentile))

                self.myPercentileText.text = String(
                    format: (
						Localization.sharedInstance.getLocalizedString("percentageTextStart", table: "EquityRewards")
						+ Localization.sharedInstance.getLocalizedString(percentMessageKey, table: "EquityRewards")
						+ Localization.sharedInstance.getLocalizedString("percentageTextEnd", table: "EquityRewards")
					),
                    Double(user_percentile)
                )

                self.hasLoadedRollout = true
                self.checkLoadingMask()
            },
            failure: {
                error,wasHandled in
                self.loadingMaskViewController.cancelLoadingMask({
                    if !wasHandled {
                        // if network error
                        if (error == TreemServiceResponseCode.NetworkError) {
                            self.errorViewController.showNoNetworkView(self.view, recover: {
                                self.getUserRollout()
                            })
                        }
                        else if (error == TreemServiceResponseCode.LockedOut) {
                            self.errorViewController.showLockedOutView(self.view, recover: {
                                self.getUserRollout()
                            })
                        }
                        else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                            self.errorViewController.showDeviceDisabledView(self.view, recover: {
                                self.getUserRollout()
                            })
                        }
                    }
                })
            }
        )
    }

    // make sure all 3 calls completed before closing loading mask
    private func checkLoadingMask() {
        if self.hasLoadedHistoricalData && self.hasLoadedRollout && self.hasLoadedTopFriends {
			self.loadGraph()

            self.loadingMaskViewController.cancelLoadingMask(nil)
        }
    }
    
    //Get the list of user's friends with the highest equity points
    private func getTopFriends() {
        TreemEquityService.sharedInstance.getTopFriends(
            parameters: [
                "limit": 5
            ],
            failureCodesHandled: [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success: {
                (data:JSON) in

                //Rebuild friend array
                self.friendsData = []
                for (_, object) in data {
                    self.friendsData.append(Rollout(json: object))
                }

                //If their friend's list was empty, show a placeholder. Otherwise, redraw the graph with data
                if (self.friendsData.count > 0) {


					//Redraw the chart with new data
					self.topFriendsTableView.reloadData()

					//set table height based on how many rows there are
					self.topFriendsTableHeight.constant = CGFloat(self.topFriendsTableView.numberOfRowsInSection(0)) * self.topFriendsTableView.rowHeight

                }
                else {
                    //Hide the table and show text saying that they have no friends with equity yet.
                    self.topFriendsTableView.hidden = true
                    self.noFriends.hidden = false
                }
                
                self.hasLoadedTopFriends = true
                self.checkLoadingMask()
            },
            failure: {
                error,wasHandled in
                self.loadingMaskViewController.cancelLoadingMask({
                    if !wasHandled {
                        // if network error
                        if (error == TreemServiceResponseCode.NetworkError) {
                            self.errorViewController.showNoNetworkView(self.view, recover: {
                                self.getTopFriends()
                            })
                        }
                        else if (error == TreemServiceResponseCode.LockedOut) {
                            self.errorViewController.showLockedOutView(self.view, recover: {
                                self.getTopFriends()
                            })
                        }
                        else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                            self.errorViewController.showDeviceDisabledView(self.view, recover: {
                                self.getTopFriends()
                            })
                        }
                    }
                })
            }
        )
    }

    //Get data for graphing the user's equity over time
	//Currently look at a change of points-per-day, over the past week.
    private func getHistoricalData() {

		var startDate = self.calendar.dateByAddingUnit(.Day, value: -(self.intervalsToShow), toDate: NSDate(), options: [])
		startDate = self.calendar.dateBySettingHour(0, minute: 0, second: 0, ofDate: startDate!, options: [])


		var parameters: Dictionary<String,AnyObject> = [:]
		parameters["scale"] = "day"
		parameters["start_date"] = self.dateFormatter.stringFromDate(startDate!)


        TreemEquityService.sharedInstance.getHistoricalData(
            parameters: parameters,
            failureCodesHandled: [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success: {
                (data:JSON) in
                self.graphData = []

				//Initialize the graph with dates that have no point values
				for day in 1...self.intervalsToShow {
					let dateInterval : NSTimeInterval? = self.calendar.dateByAddingUnit(.Day, value: day, toDate: startDate!, options: [])?.timeIntervalSince1970

					self.graphData.append(dateInterval!, CGFloat(0))
				}


				//Iterate through the data from the server to get points earned for any given day within this range
				var mostRecentMatch :	Int = 0
                for (_, object) in data {

                    //Take the ISO8601 string and turn it into an NSDate object
					let period_start    : NSDate? = NSDate(iso8601String: (object["period_start"].stringValue))

					//Temporarily adding a check since the service call is changin to use less ambiguous members
					let point_change = CGFloat ((object["point_change"] == nil ? object["points"] : object["point_change"] ).doubleValue)

                    //Track the highest and lowest values seen, so we can scale the graph appropriately
                    if (point_change > self.userPointsMax) {
                        self.userPointsMax = point_change
                    }

					//Go through the graphData array and add points to the appropriate days
					for index in mostRecentMatch..<(self.graphData.count){

						let indexDate = NSDate(timeIntervalSince1970: self.graphData[index].0)

						if (indexDate.daysFromDate(period_start!) < 1) {
							self.graphData[index].1 = point_change

							mostRecentMatch = index
							break;
						}
					}
                }
                
                self.hasLoadedHistoricalData = true
                self.checkLoadingMask()
            },
            failure: {
                error,wasHandled in
                self.loadingMaskViewController.cancelLoadingMask({
                    if !wasHandled {
                        // if network error
                        if (error == TreemServiceResponseCode.NetworkError) {
                            self.errorViewController.showNoNetworkView(self.view, recover: {
                                self.getHistoricalData()
                            })
                        }
                        else if (error == TreemServiceResponseCode.LockedOut) {
                            self.errorViewController.showLockedOutView(self.view, recover: {
                                self.getHistoricalData()
                            })
                        }
                        else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                            self.errorViewController.showDeviceDisabledView(self.view, recover: {
                                self.getHistoricalData()
                            })
                        }
                    }
                })
            }
        )
    }

    private func loadGraph() {

        //If the user has no data to graph, add in enough details to show a placeholder
        if (self.graphData.count == 0) {
            self.lastDateTime = NSDate().timeIntervalSince1970      // Current date
            self.firstDateTime = self.lastDateTime - (60 * 60 * 24 * Double(self.intervalsToShow))  // use the same scale as the service call tries to use

            self.userPointsMax = 0
        }
        else {
            self.firstDateTime = self.graphData.first!.0
            self.lastDateTime = self.graphData.last!.0
        }
        
        // main graph
        let graph = CPTXYGraph(frame: CGRectZero)
        graph.paddingLeft   = 14
        graph.paddingRight  = 0
        graph.paddingTop    = 0
        graph.paddingBottom = 0
        
        // set line style
        let lineColor = self.usersColor
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 2.0
        lineStyle.lineColor = CPTColor(CGColor: lineColor.CGColor)
        
        // main plot
        let plot = CPTScatterPlot(frame: self.graphView.frame)
        plot.dataSource     = self
        plot.dataLineStyle  = lineStyle
        plot.interpolation  = CPTScatterPlotInterpolation.Linear

        graph.addPlot(plot)
        
        /* define plot space - this decides what the x and y scales are.
            x axis' range will be from the first given date to the last one
            y axis' range will show 10 points at minimum, but also makes sure to fit the user's highest value into the graph.
				y axis' scale starts at intervals of 2 points, but will scale to make sure there are no more than 10 intervals
        */

		var yInterval : CGFloat = 2
		if (self.userPointsMax/yInterval > 5) {
			yInterval = ceil(self.userPointsMax/5)
		}
		let yRange = max(10, ceil(self.userPointsMax/yInterval)*yInterval)


        let plotSpace  = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: self.firstDateTime, length: self.lastDateTime - self.firstDateTime)
        plotSpace.yRange = CPTPlotRange(location: 0, length: yRange)

        // padding to show labels (without padding axis labels don't show)
        let plotFrame = graph.plotAreaFrame!
        plotFrame.paddingLeft       = 11
        plotFrame.paddingTop        = 6
        plotFrame.paddingBottom     = 14
        plotFrame.paddingRight      = 4
        plotFrame.masksToBorder     = false
        
        // modify axes
        let axisSet = graph.axisSet as! CPTXYAxisSet
        let xAxis   = axisSet.xAxis!
        let yAxis   = axisSet.yAxis!
        
        let textStyle = CPTMutableTextStyle()
        textStyle.fontSize = 9.0
        
        let axisFormatter = NSNumberFormatter()
        //axisFormatter.numberStyle           = NSNumberFormatterStyle.PercentStyle
        axisFormatter.minimumIntegerDigits  = 1
        axisFormatter.maximumIntegerDigits  = 3
        axisFormatter.maximumFractionDigits = 0
        axisFormatter.multiplier            = 1

        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineWidth     = 1.0
        gridLineStyle.lineColor     = CPTColor(componentRed: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
        gridLineStyle.dashPattern   = [6,2]
        
        yAxis.majorIntervalLength   = yInterval
        yAxis.majorTickLineStyle    = nil
        yAxis.minorTickLineStyle    = nil
        yAxis.labelingPolicy        = CPTAxisLabelingPolicy.FixedInterval
        yAxis.labelTextStyle        = textStyle
        yAxis.labelFormatter        = axisFormatter
        yAxis.majorGridLineStyle    = gridLineStyle
        yAxis.orthogonalPosition    = self.firstDateTime
        yAxis.labelOffset           = -6

        
        let dateAxisFormatter = CPTTimeFormatter(dateFormatter: self.dateFormatter)
        dateAxisFormatter.referenceDate = NSDate(timeIntervalSince1970: 0)

        xAxis.minorTickLineStyle            = nil
        xAxis.labelingPolicy                = CPTAxisLabelingPolicy.EqualDivisions
        xAxis.labelTextStyle                = textStyle
        xAxis.labelFormatter                = dateAxisFormatter
        xAxis.orthogonalPosition            = 0
        xAxis.preferredNumberOfMajorTicks   = UInt(self.graphData.count)
        xAxis.majorGridLineStyle            = nil
        xAxis.axisConstraints               = CPTConstraints.constraintWithRelativeOffset(0)
        xAxis.delegate                      = self
        xAxis.labelOffset                   = 3
        
        self.graphView.hostedGraph = graph
    }
    
    func numberOfRecordsForPlot(plot: CPTPlot) -> UInt {
        return UInt(graphData.count)
    }
    
    func numberForPlot(plot: CPTPlot, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject? {

        // x value (Date)
        if(fieldEnum == UInt(CPTScatterPlotField.X.rawValue)) {
            return self.graphData[Int(idx)].0
        }
        // y value (Points)
        else {
            return self.graphData[Int(idx)].1
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friendsData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EquityFriendsCell") as! EquityFriendsCell
        
        if (self.friendsData.indices.contains(indexPath.row)){

			cell.friendsName.text = self.friendsData[indexPath.row].user_first_last
			cell.friendPoints.text = self.numberFormatter.stringFromNumber(self.friendsData[indexPath.row].points)! + " pts"
			cell.friendsChange.points = self.friendsData[indexPath.row].change_today

			let friendPercent = self.friendsData[indexPath.row].percentile
			let friendPercentText = String(format: "%.0f", friendPercent*100)
			cell.friendPercentage.text = friendPercentText + "%"
			cell.friendPercentage.colorSubstring(friendPercentText, color: self.getPercentileColor(friendPercent))


            cell.layoutMargins  = UIEdgeInsetsZero
        }
        
        return cell
    }


	//Taking in the user's percentile (on a scale of 0.00 to 1.00), and using an array of colors, determine the appropriate color to show

	private func getPercentileColor (percentile: Double) -> UIColor {
		return self.percentileColors[min(Int(percentile * Double(self.percentileColors.count)), (self.percentileColors.count-1))]
	}
}
