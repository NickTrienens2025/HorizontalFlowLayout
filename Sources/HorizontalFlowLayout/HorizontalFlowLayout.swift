import SwiftUI

/// A layout that arranges its subviews in horizontal lines and
/// wraps them to the next line if they exceed the available width.
/// 
/// This layout is useful for creating horizontal lists or grids where items are arranged in rows and wrap to the next line when they exceed the available width.
/// 
/// The layout supports customizing the alignment, spacing, and whether the width is based on the content or the available space.
/// 
/// Example usage:
/// ```swift
/// HorizontalFlowLayout(alignment: .trailing,
///                      horizontalSpacing: 2) {
///     ForEach(tags) {
///         Text($0.text)
///              .foregroundColor(Color.white)
///              .padding(.horizontal, 4)
///              .padding(.vertical, 4)
///              .background(Color.gray)
///              .cornerRadius(8)
///          }
///      } 
/// ```

@MainActor
public struct HorizontalFlowLayout: @preconcurrency Layout {
    /// The alignment guide for subviews.
    public var alignment: Alignment
    
    /// The horizontal distance between adjacent subviews in a row.
    public var horizontalSpacing: CGFloat?
    
    /// The vertical distance between consecutive rows.
    public var verticalSpacing: CGFloat?
    
    /// Creates a wrapping horizontal stack with the given configuration.
    /// - Parameters:
    ///   - alignment: Alignment for subviews.
    ///   - horizontalSpacing: Spacing between items in a row.
    ///   - verticalSpacing: Spacing between rows.
    ///   - fitContentWidth: Whether to fit the width to the content or fill the available space.
    @inlinable
    public init(alignment: Alignment = .center,
                horizontalSpacing: CGFloat? = nil,
                verticalSpacing: CGFloat? = nil) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .horizontal
        return properties
    }
    
    // MARK: - Cache
    public struct Cache {
        /// The minimal size of the entire layout (used to early-return if subviews can't fit).
        var minSize: CGSize
        
        /// A cached set of rows and a hash representing the last arrangement.
        var rows: (hash: Int, rows: [Row])?
    }
    
    public func makeCache(subviews: Subviews) -> Cache {
        Cache(minSize: minSize(subviews: subviews))
    }
    
    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.minSize = minSize(subviews: subviews)
    }
    
    // MARK: - Layout Calculations
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let rows = arrangeRows(proposal: proposal, subviews: subviews, cache: &cache)
        if rows.isEmpty { return cache.minSize }
        
        // Determine total width
        var width = rows.map(\.width).max() ?? 0
        if  let proposedWidth = proposal.width {
            width = max(width, proposedWidth)
        }
        
        // Determine total height (bottom of the last row)
        let height = (rows.last?.yOffset ?? 0) + (rows.last?.height ?? 0)
        
        return CGSize(width: width, height: height)
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let rows = arrangeRows(proposal: proposal, subviews: subviews, cache: &cache)
        let anchor = UnitPoint(alignment)
        
        for row in rows {
            for element in row.elements {
                // Adjust x-position based on alignment
                let x = element.xOffset + anchor.x * (bounds.width - row.width)
                // Adjust y-position based on alignment
                let y = row.yOffset + anchor.y * (row.height - element.size.height)
                let point = CGPoint(x: x + bounds.minX, y: y + bounds.minY)
                
                subviews[element.index].place(
                    at: point,
                    anchor: .topLeading,
                    proposal: proposal
                )
            }
        }
    }

    /// Represents a single row of subviews.
    struct Row {
        /// Represents a single element within a row
        struct Element {
            var index: Int
            var size: CGSize
            var xOffset: CGFloat
        }
        
        var elements: [Element] = []
        var yOffset: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
    
    /// Creates rows of subviews given the size proposal and updates the cache.
    private func arrangeRows(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> [Row] {
        // Early return if no subviews
        guard !subviews.isEmpty else { return [] }
        
        // If minimal size is bigger than the proposed size, no layout is possible
        let fitsWidth = cache.minSize.width <= (proposal.width ?? .infinity)
        let fitsHeight = cache.minSize.height <= (proposal.height ?? .infinity)
        guard fitsWidth && fitsHeight else { return [] }
        
        // Calculate subview sizes
        let sizes = subviews.map { $0.sizeThatFits(proposal) }
        
        // Check if we already have a cached result for these sizes + proposal
        let hash = computeHash(proposal: proposal, sizes: sizes)
        if let cached = cache.rows, cached.hash == hash {
            return cached.rows
        }
        
        // Arrange subviews into rows
        var rows: [Row] = []
        var currentRow = Row()
        var currentX: CGFloat = 0
        
        for index in subviews.indices {
            let size = sizes[index]
            // Horizontal spacing from the last item
            var spacing = currentRow.elements.last.map {
                horizontalSpacing(subviews[$0.index], subviews[index])
            } ?? 0
            
            let availableWidth = proposal.width ?? .infinity
            
            // If current item is wider than available width, and we have items in current row,
            // finish current row first
            if size.width > availableWidth && !currentRow.elements.isEmpty {
                currentRow.width = currentX
                rows.append(currentRow)
                
                // Start a new row
                currentRow = Row()
                currentX = 0
                spacing = 0
            }
            
            // If we can't fit the new item in the current row, wrap to the next row
            if currentX + size.width + spacing > availableWidth,
               !currentRow.elements.isEmpty {
                currentRow.width = currentX
                rows.append(currentRow)
                
                // Start a new row
                currentRow = Row()
                currentX = 0
                spacing = 0
            }
            
            // Add item to current row - even if it's wider than available width,
            // it still needs to be placed somewhere
            currentRow.elements.append(Row.Element(index: index, size: size, xOffset: currentX + spacing))
            currentX += size.width + spacing
            
            // If this item is wider than available width, immediately start a new row
            if size.width > availableWidth {
                currentRow.width = currentX
                rows.append(currentRow)
                
                // Start a new row
                currentRow = Row()
                currentX = 0
            }
        }
        
        // Append the last row
        if !currentRow.elements.isEmpty {
            currentRow.width = currentX
            rows.append(currentRow)
        }
        
        // Position rows vertically
        var currentY: CGFloat = 0
        var previousMaxHeightIndex: Int?
        
        for i in rows.indices {
            // Find the tallest element in this row
            let maxHeightElement = rows[i].elements.max {
                $0.size.height < $1.size.height
            }
            guard let tallestIndex = maxHeightElement?.index else { continue }
            
            // Determine vertical spacing from the previous row's tallest element
            let spacing = previousMaxHeightIndex.map {
                verticalSpacing(subviews[$0], subviews[tallestIndex])
            } ?? 0
            
            rows[i].yOffset = currentY + spacing
            rows[i].height = maxHeightElement?.size.height ?? 0
            currentY += rows[i].height + spacing
            previousMaxHeightIndex = tallestIndex
        }
        
        cache.rows = (hash, rows)
        return rows
    }
    
    /// Computes a hash for the layout arrangement based on the proposed size and subview sizes.
    private func computeHash(proposal: ProposedViewSize, sizes: [CGSize]) -> Int {
        let proposal = proposal.replacingUnspecifiedDimensions(by: .infinity)
        var hasher = Hasher()
        hasher.combine(proposal.width)
        hasher.combine(proposal.height)
        for size in sizes {
            hasher.combine(size.width)
            hasher.combine(size.height)
        }
        return hasher.finalize()
    }
    
    /// The minimum size needed to lay out all subviews (with `.zero` proposal).
    private func minSize(subviews: Subviews) -> CGSize {
        subviews
            .map { $0.sizeThatFits(.zero) }
            .reduce(into: .zero) { result, size in
                result.width = max(result.width, size.width)
                result.height = max(result.height, size.height)
            }
    }
    
    /// Computes horizontal spacing between two subviews.
    private func horizontalSpacing(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        if let horizontalSpacing { return horizontalSpacing }
        return lhs.spacing.distance(to: rhs.spacing, along: .horizontal)
    }
    
    /// Computes vertical spacing between two subviews.
    private func verticalSpacing(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        if let verticalSpacing { return verticalSpacing }
        return lhs.spacing.distance(to: rhs.spacing, along: .vertical)
    }
}

private extension UnitPoint {
    /// Converts an `Alignment` to a corresponding `UnitPoint`.
    init(_ alignment: Alignment) {
        switch alignment {
        case .leading:         self = .leading
        case .topLeading:      self = .topLeading
        case .top:             self = .top
        case .topTrailing:     self = .topTrailing
        case .trailing:        self = .trailing
        case .bottomTrailing:  self = .bottomTrailing
        case .bottom:          self = .bottom
        case .bottomLeading:   self = .bottomLeading
        default:               self = .center
        }
    }
}

private extension CGSize {
    static var infinity: Self { .init(width: CGFloat.infinity, height: CGFloat.infinity) }
}
