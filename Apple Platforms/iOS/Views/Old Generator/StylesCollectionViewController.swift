//
//  StylesCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 12/4/24.
//

import UIKit

private let reuseIdentifier = "styleCollectionCell"

struct WrappedStyle {
    let name: String
    let style: Style
    let categories: [String]
}

class StylesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating {

    var delegate: StylesTableViewControllerDelegate?

    @IBOutlet weak var layout: UICollectionViewFlowLayout!

    var categories: [Category] = [] {
        didSet {
            categories.sort { c1, c2 in
                c1.title < c2.title
            }
            categories.insert(Category(title: "Default", styles: ["None"]), at: 0)
            collectionView.reloadData()
        }
    }

    var styles: [String: Style] = [:]
    var wrappedStyles: [WrappedStyle] = []
    var activeStyles: [WrappedStyle] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.hidesNavigationBarDuringPresentation = false
        search.searchBar.placeholder = "Search styles"
        navigationItem.searchController = search

        Task {
            await loadData()
        }
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
                return WrappedStyle(name: key, style: value, categories: categoriesForStyle)
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
            Log.debug(uncategorizedStyles.sorted().joined(separator: ", "))
            newCategories.append(Category(title: "uncategorized", styles: uncategorizedStyles.sorted()))
            self.categories = newCategories
        } catch {
            Log.error("Unable to grab style categories: \(error.localizedDescription)")
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        Log.debug("Searched for: \(text)")
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

        // Configure the cell
        cell.styleNameLabel.text = activeStyles[indexPath.item].name

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let style = activeStyles[indexPath.item]
        delegate?.selectedStyle(title: style.name, style: style.style)
        navigationController?.popViewController(animated: true)
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
        let newCellWidth = (collectionView.bounds.width - contentHorizontalSpaces) / 2
        Log.debug(collectionView.bounds.width)
        let newHeight = 100.0
//        let data = indexPath.section == 0 ? presetAlbums[indexPath.row] : smartAlbums[indexPath.row]
//        let newHeight = AlbumCollectionViewCell.getProductHeightForWidth(props: data, width: newCellWidth)
        Log.debug("returning \(newCellWidth)x\(newHeight)")
        return CGSize(width: newCellWidth, height: newCellWidth)
    }

}
