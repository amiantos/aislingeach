//
//  StylesCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 12/4/24.
//

import UIKit
import SDWebImage

private let reuseIdentifier = "styleCollectionCell"

struct WrappedStyle {
    let name: String
    let style: Style
    let categories: [String]
    let aspectRatio: String
}

class StylesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, UISearchBarDelegate {

    var delegate: StylesTableViewControllerDelegate?

    @IBOutlet weak var layout: UICollectionViewFlowLayout!

    var categories: [Category] = [] {
        didSet {
            categories.sort { c1, c2 in
                c1.title < c2.title
            }
            categories.insert(Category(title: "Default", styles: ["None"]), at: 0)
        }
    }

    var styles: [String: Style] = [:]
    var wrappedStyles: [WrappedStyle] = []
    var activeStyles: [WrappedStyle] = []
    var stylePreviews: [String: [String: URL]] = [:]
    var styleHashes: [String: String] = [:]

    var previewType: String = "person"
    var previewSize: String = "regular"
    var previewRatio: String = "zoomed"

    var menuButton: UIBarButtonItem = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.hidesNavigationBarDuringPresentation = false
        search.searchBar.placeholder = "Search styles"
        search.searchBar.delegate = self
        search.showsSearchResultsController = true
        search.automaticallyShowsCancelButton = false
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false

        previewType = UserDefaults.standard.stylesPreviewType
        previewSize = UserDefaults.standard.stylesPreviewSize
        previewRatio = UserDefaults.standard.stylesDisplayRatio

        // setup menu
        menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            menu: UIMenu(
                children: [
                    UIMenu(
                        title: "Preview Subject",
                        options: .displayInline,
                        children: [
                            UIDeferredMenuElement.uncached { [weak self] completion in
                                let actions = [
                                    UIAction(
                                        title: "Person",
                                        image: UIImage(systemName: "person"),
                                        state: self?.previewType == "person" ? .on : .off,
                                        handler: { [self] _ in
                                            self?.switchPreviewType("person")
                                        }
                                    ),
                                    UIAction(
                                        title: "Place",
                                        image: UIImage(systemName: "building.2"),
                                        state: self?.previewType == "place" ? .on : .off,
                                        handler: { [self] _ in
                                            self?.switchPreviewType("place")
                                        }
                                    ),
                                    UIAction(
                                        title: "Thing",
                                        image: UIImage(systemName: "car"),
                                        state: self?.previewType == "thing" ? .on : .off,
                                        handler: { [self] _ in
                                            self?.switchPreviewType("thing")
                                        }
                                    )
                                ]
                                completion(actions)
                            }
                        ]
                    ),
                    UIMenu(title: "Preview Size", options: .displayInline, children: [
                        UIDeferredMenuElement.uncached { [weak self] completion in
                            let actions = [
                                UIAction(
                                    title: "Regular",
                                    image: UIImage(systemName: "square.resize.down"),
                                    state: self?.previewSize == "regular" ? .on : .off,
                                    handler: { [self] _ in
                                        self?.switchPreviewSize("regular")
                                    }
                                ),
                                UIAction(
                                    title: "Large",
                                    image: UIImage(systemName: "square.resize.up"),
                                    state: self?.previewSize == "large" ? .on : .off,
                                    handler: { [self] _ in
                                        self?.switchPreviewSize("large")
                                    }
                                )
                            ]
                            completion(actions)
                        }
                    ]),
                    UIMenu(title: "Preview Type", options: .displayInline, children: [
                        UIDeferredMenuElement.uncached { [weak self] completion in
                            let actions = [
                                UIAction(
                                    title: "Fill",
                                    image: UIImage(systemName: "square"),
                                    state: self?.previewRatio == "zoomed" ? .on : .off,
                                    handler: { [self] _ in
                                        self?.switchPreviewRatio("zoomed")
                                    }
                                ),
                                UIAction(
                                    title: "Fit",
                                    image: UIImage(systemName: "aspectratio"),
                                    state: self?.previewRatio == "actual" ? .on : .off,
                                    handler: { [self] _ in
                                        self?.switchPreviewRatio("actual")
                                    }
                                )
                            ]
                            completion(actions)
                        }
                    ])
                ]
            )
        )
        navigationItem.rightBarButtonItem = menuButton

        Task {
            await loadData()
        }
    }

    func switchPreviewType(_ type: String) {
        Log.debug("Switching preview type to \(type)")
        previewType = type
        UserDefaults.standard.set(stylesPreviewType: type)
        collectionView.reloadData()
    }

    func switchPreviewSize(_ size: String) {
        Log.debug("Switching preview size to \(size)")
        previewSize = size
        UserDefaults.standard.set(stylesPreviewSize: size)
        collectionView.reloadData()
    }

    func switchPreviewRatio(_ ratio: String) {
        Log.debug("Switching preview ratio to \(ratio)")
        previewRatio = ratio
        UserDefaults.standard.set(stylesDisplayRatio: ratio)
        collectionView.reloadData()
    }

    func loadData() async {
        Log.debug("Fetching styles")
        // https://raw.githubusercontent.com/Haidra-Org/AI-Horde-Styles/main/categories.json
        let url = URL(string: "https://raw.githubusercontent.com/Haidra-Org/AI-Horde-Styles/main/categories.json")!
        let url2 = URL(string: "https://raw.githubusercontent.com/Haidra-Org/AI-Horde-Styles/main/styles.json")!
        let urlSession = URLSession.shared
        do {
            let (data, _) = try await urlSession.data(from: url)
            let categories = try JSONDecoder().decode([String: [String]].self, from: data)

            let (data2, _) = try await urlSession.data(from: url2)
            self.styles = try JSONDecoder().decode([String: Style].self, from: data2)
            var styleArray = self.styles

            wrappedStyles = styleArray.compactMap{ key, value in
                let categoriesForStyle: [String] = categories.compactMap { category, styles in
                    if styles.contains(where: { $0 == key }) {
                        return category
                    }
                    return nil
                }
                Log.debug("Categories for \(key): \(categoriesForStyle)")
                var aspectRatio = ""
                if value.width != nil && value.height != nil {
                    let gcd = gcdBinaryRecursiveStein(value.width!, value.height!)
                    aspectRatio = "\(value.width! / gcd):\(value.height! / gcd)"
                }
                return WrappedStyle(name: key, style: value, categories: categoriesForStyle, aspectRatio: aspectRatio)
            }
            wrappedStyles = wrappedStyles.sorted { $0.name < $1.name }
            activeStyles = wrappedStyles

            var newCategories: [Category] = categories.compactMap { key, value in
                let stylesOnly = value.compactMap { value in
                    if self.styles.contains(where: { $0.0 == value }) {
                        styleArray = styleArray.filter { $0.0 != value }
                        return value
                    }
                    return nil
                }
                if stylesOnly.isEmpty { return nil }
                return Category(title: key, styles: stylesOnly.sorted())
            }
            let uncategorizedStyles = styleArray.map { return $0.0 }
            newCategories.append(Category(title: "uncategorized", styles: uncategorizedStyles.sorted()))
            self.categories = newCategories

            let hashUrl = URL(string:"https://raw.githubusercontent.com/amiantos/AI-Horde-Styles-Previews/refs/heads/main/hashes.json")!
            let (hashData, _) = try await urlSession.data(from: hashUrl)
            self.styleHashes = try JSONDecoder().decode([String: String].self, from: hashData)

            let previewsUrl = URL(string: "https://raw.githubusercontent.com/amiantos/AI-Horde-Styles-Previews/refs/heads/main/previews.json")!
            let (previewsData, _) = try await urlSession.data(from: previewsUrl)
            self.stylePreviews = try JSONDecoder().decode([String: [String: URL]].self, from: previewsData)

            collectionView.reloadData()

            if !UserDefaults.standard.stylesLastSearch.isEmpty {
                navigationItem.searchController?.searchBar.text = UserDefaults.standard.stylesLastSearch
            }
        } catch {
            Log.error("Unable to grab style categories: \(error.localizedDescription)")
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        Log.debug("Searched for: \(text)")
        UserDefaults.standard.set(stylesLastSearch: text)
        if text.isEmpty {
            activeStyles = wrappedStyles
        } else {
            activeStyles = wrappedStyles.filter { value in
                let categories = value.categories.filter { $0.lowercased().contains(text.lowercased()) }
                if value.name.lowercased().contains(text.lowercased()) || !categories.isEmpty {
                    return true
                }
                return false
            }
        }
        collectionView.reloadData()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty ?? true {
            UserDefaults.standard.set(stylesLastSearch: "")
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activeStyles.count
    }



    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "styleCollectionCell", for: indexPath) as! StyleCollectionViewCell
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let style = activeStyles[indexPath.item]
        delegate?.selectedStyle(title: style.name, style: style.style)
        navigationController?.popViewController(animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Configure the cell
        guard let cell = cell as? StyleCollectionViewCell else { return }
        cell.styleNameLabel.text = activeStyles[indexPath.item].name
        cell.aspectRatioLabel.text = activeStyles[indexPath.item].aspectRatio
        if let previewUrls = stylePreviews[activeStyles[indexPath.item].name] {
            if let previewImageURL = previewUrls[previewType] {
                cell.previewImageView.sd_setImage(with: previewImageURL)
                cell.previewImageView.contentMode = previewRatio == "zoomed" ? .scaleAspectFill : .scaleAspectFit
            }
        }
    }

//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "categorySectionView", for: indexPath)  as! StyleCollectionReusableView
//        cell.categoryLabel.text = categories[indexPath.section].title
//        return cell
//    }



    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentHorizontalSpaces = layout.minimumInteritemSpacing + layout.sectionInset.left + layout.sectionInset.right
        let divisor = previewSize == "regular" ? 2.0 : 1.0
        let newCellWidth = (collectionView.bounds.width - contentHorizontalSpaces) / divisor
        return CGSize(width: newCellWidth, height: newCellWidth)
    }

}
