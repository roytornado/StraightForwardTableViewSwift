import Foundation
import UIKit

@objc protocol SFTableViewEventDelegate{
  optional func didConfigureCell(tableView: SFTableView, indexPath: NSIndexPath)
}


@objc protocol SFTableViewCellCompatible {
  static func heightForCell(obj: AnyObject, width: CGFloat) -> CGFloat
  func configureCell(obj: AnyObject, width: CGFloat)
}

class SFTableCellDataHolder {
  var obj : AnyObject!
  var cellClass : AnyClass!
  var cellClassName : String {
    var name : String = "\(cellClass!)"
    if name.containsString(".") {
      name = name.componentsSeparatedByString(".").last!
    }
    return name
  }
}

class SFTableSectionHolder {
  var allCells = [SFTableCellDataHolder]()
  var sectionHeaderView : UIView?
  var sectionFooterView : UIView?
  var sectionHeaderHeight : CGFloat = 0
  var sectionFooterHeight : CGFloat = 0
}

@objc class SFTableView : UITableView, UITableViewDelegate, UITableViewDataSource {
  var allSections = [SFTableSectionHolder]()
  weak var eventDelegate : SFTableViewEventDelegate?
  
  var refreshControlView : UIRefreshControl?
  var indicatorView = UIActivityIndicatorView()
  
  convenience init() {
    self.init(frame: CGRect.zero, style: UITableViewStyle.Plain)
    setup()
  }
  
  override func awakeFromNib() {
    setup()
  }
  
  override init(frame: CGRect, style: UITableViewStyle) {
    super.init(frame: frame, style: style)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder: ) has not been implemented")
  }
  
  func setup(){
    backgroundColor = UIColor.whiteColor()
    separatorStyle = .None
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    estimatedRowHeight = 100.0
    delegate = self
    dataSource = self
    indicatorView.activityIndicatorViewStyle = .Gray
    addSubview(indicatorView)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    indicatorView.frame = CGRectMake(frame.width / 2 - 20 / 2, frame.height / 2 - 20 / 2, 20, 20)
  }
  
  func scrollToBottom(animated: Bool) {
    if numberOfSections > 0 {
      let lastSectionIndex = numberOfSections - 1
      if numberOfRowsInSection(lastSectionIndex) > 0 {
        let lastItemIndex = numberOfRowsInSection(lastSectionIndex) - 1
        let lastIndexPath = NSIndexPath(forRow: lastItemIndex, inSection: lastSectionIndex)
        scrollToRowAtIndexPath(lastIndexPath, atScrollPosition: .None, animated: false)
      }
    }
  }
  
  func setupPullToRefresh(){
    refreshControlView = UIRefreshControl()
    refreshControlView?.addTarget(self, action: "reloadByUser", forControlEvents: .ValueChanged)
    refreshControlView?.tintColor = UIColor.grayColor()
    addSubview(refreshControlView!)
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    if allSections.count == 0 {
      return
    }
    let y = scrollView.contentOffset.y + scrollView.frame.height - scrollView.contentInset.bottom;
    let h = scrollView.contentSize.height
    if y > h - scrollView.frame.height {
    }
  }
  
  func showLoading(){
    indicatorView.hidden = false
    indicatorView.startAnimating()
  }
  
  func hideLoading(){
    indicatorView.hidden = true
    indicatorView.stopAnimating()
    refreshControlView?.endRefreshing()
  }
  
  func reloadByUser(){
    reload()
  }
  
  func reload(){
  }
  
  func isEmpty() -> Bool {
    for section in allSections {
      if section.allCells.count > 0 {
        return false
      }
    }
    return true
  }
  
  func clean(){
    allSections.removeAll()
    reloadData()
  }
  
  func registerNibCell(name: String){
    registerNib(UINib(nibName: name, bundle: nil), forCellReuseIdentifier: name)
  }
  
  func registerClassCell(aClass: AnyClass){
    let name : String = "\(aClass)"
    registerClass(aClass, forCellReuseIdentifier: name)
  }
  
  func addSection() -> SFTableSectionHolder{
    let section = SFTableSectionHolder()
    allSections.append(section)
    return section
  }
  
  func addCell(obj: AnyObject, cellClass: AnyClass, var section: SFTableSectionHolder? = nil) -> SFTableCellDataHolder{
    if (section == nil) {
      section = allSections.last
    }
    if (section == nil) {
      section = addSection()
    }
    let cell = SFTableCellDataHolder()
    cell.obj = obj
    cell.cellClass = cellClass
    section?.allCells.append(cell)
    return cell
  }
  
  func getCell(index: NSIndexPath) -> SFTableCellDataHolder{
    let section = allSections[index.section]
    let cell = section.allCells[index.row]
    return cell
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return allSections.count
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section = allSections[section]
    return section.allCells.count
  }
  
  func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let section = allSections[section]
    return section.sectionHeaderView == nil ? 0 : section.sectionHeaderHeight
  }
  
  func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    let section = allSections[section]
    return section.sectionFooterView == nil ? 0 : section.sectionFooterHeight
  }
  
  func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return allSections[section].sectionHeaderView
  }
  
  func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return allSections[section].sectionFooterView
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    let section = allSections[indexPath.section]
    let cell = section.allCells[indexPath.row]
    let targetCellClass = cell.cellClass as! SFTableViewCellCompatible.Type
    let height = targetCellClass.heightForCell(cell.obj!, width: tableView.frame.width)
    return height
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let section = allSections[indexPath.section]
    let cell = section.allCells[indexPath.row]
    let view = tableView.dequeueReusableCellWithIdentifier(cell.cellClassName) as! SFTableViewCellCompatible
    view.configureCell(cell.obj!, width: tableView.frame.width)
    eventDelegate?.didConfigureCell?(self, indexPath: indexPath)
    return view as! UITableViewCell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
}
