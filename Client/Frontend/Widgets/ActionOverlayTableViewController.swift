/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import SnapKit

private struct ActionOverlayTableViewUX {
    static let HeaderHeight: CGFloat = 74
    static let RowHeight: CGFloat = 56
}

class ActionOverlayTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    fileprivate(set) var actions: [ActionOverlayTableViewAction]

    fileprivate var site: Site
    fileprivate var tableView = UITableView()
    fileprivate var headerImage: UIImage?
    fileprivate var headerImageBackgroundColor: UIColor?
    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(ActionOverlayTableViewController.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        return tapRecognizer
    }()

    lazy var visualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.frame = self.view.bounds
        visualEffectView.alpha = 0.90
        return visualEffectView
    }()

    init(site: Site, actions: [ActionOverlayTableViewAction], siteImage: UIImage?, siteBGColor: UIColor?) {
        self.site = site
        self.actions = actions
        self.headerImage = siteImage
        self.headerImageBackgroundColor = siteBGColor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear.withAlphaComponent(0.4)
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Overlay"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        tableView.register(ActionOverlayTableViewCell.self, forCellReuseIdentifier: "ActionOverlayTableViewCell")
        tableView.register(ActionOverlayTableViewHeader.self, forHeaderFooterViewReuseIdentifier: "ActionOverlayTableViewHeader")
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.isScrollEnabled = true
        tableView.bounces = false
        tableView.layer.cornerRadius = 10
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"

        tableView.snp.makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(290)
            setHeightConstraint(make)
        }
    }

    fileprivate func setHeightConstraint(_ make: ConstraintMaker) {
        make.height.lessThanOrEqualTo(view.bounds.height)
        make.height.equalTo(ActionOverlayTableViewUX.HeaderHeight + CGFloat(actions.count) * ActionOverlayTableViewUX.RowHeight).priority(10)
    }

    func dismiss(_ gestureRecognizer: UIGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    override func updateViewConstraints() {
        tableView.snp.updateConstraints { make in
            setHeightConstraint(make)
        }
        super.updateViewConstraints()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateViewConstraints()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = actions[indexPath.row]
        guard let handler = actions[indexPath.row].handler else {
            return
        }
        return handler(action)
    }

    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ActionOverlayTableViewUX.RowHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ActionOverlayTableViewUX.HeaderHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionOverlayTableViewCell", for: indexPath) as! ActionOverlayTableViewCell
        let action = actions[indexPath.row]
        cell.configureCell(action.title, imageString: action.iconString)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ActionOverlayTableViewHeader") as! ActionOverlayTableViewHeader
        header.configureWithSite(site, image: headerImage, imageBackgroundColor: headerImageBackgroundColor)
        return header
    }
}

class ActionOverlayTableViewHeader: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        titleLabel.textColor = SimpleHighlightCellUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 3
        return titleLabel
    }()

    lazy var descriptionLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontDescriptionActivityStream
        titleLabel.textColor = SimpleHighlightCellUX.DescriptionLabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.center
        siteImageView.layer.cornerRadius = SimpleHighlightCellUX.CornerRadius
        return siteImageView
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        isAccessibilityElement = true

        descriptionLabel.numberOfLines = 1
        titleLabel.numberOfLines = 1

        contentView.backgroundColor = UIConstants.PanelBackgroundColor

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(titleLabel)

        siteImageView.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(12)
            make.size.equalTo(SimpleHighlightCellUX.SiteImageViewSize)
        }

        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(siteImageView.snp.trailing).offset(12)
            make.trailing.equalTo(contentView).inset(12)
            make.top.equalTo(siteImageView).offset(7)
        }

        descriptionLabel.snp.remakeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(siteImageView).inset(7)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithSite(_ site: Site, image: UIImage?, imageBackgroundColor: UIColor?) {
        self.siteImageView.backgroundColor = imageBackgroundColor
        self.siteImageView.image = image?.createScaled(SimpleHighlightCellUX.IconSize) ?? SimpleHighlightCellUX.PlaceholderImage
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        self.descriptionLabel.text = site.tileURL.baseDomain
    }
}
