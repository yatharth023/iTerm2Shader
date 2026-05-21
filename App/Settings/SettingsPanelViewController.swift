import Cocoa

class SettingsPanelViewController: NSViewController {

    // MARK: - UI Components

    private var scrollView: NSScrollView!
    private var contentView: NSView!

    private var presetPopUpButton: NSPopUpButton!

    private var intensitySlider: NSSlider!
    private var intensityLabel: NSTextField!

    private var speedSlider: NSSlider!
    private var speedLabel: NSTextField!

    private var depthSlider: NSSlider!
    private var depthLabel: NSTextField!

    private var contrastSlider: NSSlider!
    private var contrastLabel: NSTextField!

    private var colorTempSlider: NSSlider!
    private var colorTempLabel: NSTextField!

    private var glowSlider: NSSlider!
    private var glowLabel: NSTextField!

    private var typingReactivitySlider: NSSlider!
    private var typingReactivityLabel: NSTextField!

    private var resetButton: NSButton!
    private var closeButton: NSButton!

    // MARK: - Data

    private var currentParameters: PresetParameters
    private let allPresets: [ShaderPreset]

    // MARK: - Callbacks

    var onParametersChanged: ((PresetParameters) -> Void)?
    var onPresetChanged: ((ShaderPreset) -> Void)?
    var onClose: (() -> Void)?

    // MARK: - Initialization

    init(currentParameters: PresetParameters, allPresets: [ShaderPreset]) {
        self.currentParameters = currentParameters
        self.allPresets = allPresets
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        let frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let rootView = NSView(frame: frame)
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor(white: 0.12, alpha: 0.96).cgColor
        rootView.layer?.cornerRadius = 12

        self.view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateWithCurrentValues()
    }

    // MARK: - UI Setup

    private func setupUI() {
        let padding: CGFloat = 20
        let contentWidth = view.bounds.width - padding * 2

        // Calculate exact content height needed
        let topPadding: CGFloat = 20
        let titleHeight: CGFloat = 44
        let presetLabelHeight: CGFloat = 24
        let presetDropdownHeight: CGFloat = 36
        let presetSpacing: CGFloat = 10
        let dividerHeight: CGFloat = 30
        let sliderRowHeight: CGFloat = 70  // 24 for label + 30 for slider + 16 spacing
        let buttonHeight: CGFloat = 48
        let buttonSpacing: CGFloat = 12
        let bottomPadding: CGFloat = 30

        // Total content height must be LARGER than view height to enable scrolling
        let totalHeight = topPadding + titleHeight + presetLabelHeight + presetSpacing +
                         presetDropdownHeight + dividerHeight +
                         (sliderRowHeight * 7) + dividerHeight +
                         buttonHeight + buttonSpacing + buttonHeight + bottomPadding

        // Create scroll view
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.verticalScrollElasticity = .allowed
        scrollView.usesPredominantAxisScrolling = false
        view.addSubview(scrollView)

        // Create flipped content view so y=0 is at TOP
        contentView = FlippedView(frame: NSRect(x: 0, y: 0, width: view.bounds.width, height: totalHeight))
        scrollView.documentView = contentView

        var yOffset: CGFloat = topPadding

        // Title - at top
        let titleLabel = createLabel(text: "Shader Settings", fontSize: 26, weight: .semibold)
        titleLabel.frame = NSRect(x: padding, y: yOffset, width: contentWidth, height: 44)
        titleLabel.textColor = NSColor(white: 0.95, alpha: 1.0)
        contentView.addSubview(titleLabel)
        yOffset += 44

        // Preset Selector
        let presetLabel = createLabel(text: "Preset Theme", fontSize: 15, weight: .medium)
        presetLabel.frame = NSRect(x: padding, y: yOffset, width: contentWidth, height: 24)
        contentView.addSubview(presetLabel)
        yOffset += 34

        presetPopUpButton = NSPopUpButton(frame: NSRect(x: padding, y: yOffset, width: contentWidth, height: 36))
        presetPopUpButton.target = self
        presetPopUpButton.action = #selector(presetChanged(_:))

        for preset in allPresets {
            presetPopUpButton.addItem(withTitle: preset.name)
        }

        contentView.addSubview(presetPopUpButton)
        yOffset += 46

        // Divider
        let divider1 = createDivider(y: yOffset, width: contentWidth)
        contentView.addSubview(divider1)
        yOffset += 30

        // Parameter Sliders
        (intensitySlider, intensityLabel) = createParameterRow(
            title: "Intensity",
            minValue: 0.0,
            maxValue: 1.0,
            yOffset: &yOffset,
            action: #selector(intensityChanged(_:))
        )

        (speedSlider, speedLabel) = createParameterRow(
            title: "Speed",
            minValue: 0.0,
            maxValue: 3.0,
            yOffset: &yOffset,
            action: #selector(speedChanged(_:))
        )

        (depthSlider, depthLabel) = createParameterRow(
            title: "Depth",
            minValue: 0.5,
            maxValue: 5.0,
            yOffset: &yOffset,
            action: #selector(depthChanged(_:))
        )

        (contrastSlider, contrastLabel) = createParameterRow(
            title: "Contrast",
            minValue: 0.0,
            maxValue: 1.0,
            yOffset: &yOffset,
            action: #selector(contrastChanged(_:))
        )

        (colorTempSlider, colorTempLabel) = createParameterRow(
            title: "Color Temperature",
            minValue: 3000.0,
            maxValue: 12000.0,
            yOffset: &yOffset,
            action: #selector(colorTempChanged(_:))
        )

        (glowSlider, glowLabel) = createParameterRow(
            title: "Glow",
            minValue: 0.0,
            maxValue: 1.0,
            yOffset: &yOffset,
            action: #selector(glowChanged(_:))
        )

        (typingReactivitySlider, typingReactivityLabel) = createParameterRow(
            title: "Typing Reactivity",
            minValue: 0.0,
            maxValue: 1.0,
            yOffset: &yOffset,
            action: #selector(typingReactivityChanged(_:))
        )

        // Divider
        let divider2 = createDivider(y: yOffset, width: contentWidth)
        contentView.addSubview(divider2)
        yOffset += 30

        // Reset Button (INSIDE scroll view)
        resetButton = NSButton(frame: NSRect(x: padding, y: yOffset, width: contentWidth, height: 48))
        resetButton.title = "Reset to Preset Defaults"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetToDefaults)
        contentView.addSubview(resetButton)
        yOffset += 60

        // Close Button (INSIDE scroll view, below reset button)
        closeButton = NSButton(frame: NSRect(x: padding, y: yOffset, width: contentWidth, height: 48))
        closeButton.title = "Close Settings"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closePanel)
        closeButton.keyEquivalent = "\u{1b}" // ESC key
        contentView.addSubview(closeButton)
        yOffset += 48

        print("✅ Content layout complete - Total height: \(contentView.bounds.height), Used: \(yOffset)")
    }

    private func createParameterRow(title: String, minValue: Double, maxValue: Double, yOffset: inout CGFloat, action: Selector) -> (NSSlider, NSTextField) {
        let padding: CGFloat = 20
        let contentWidth = contentView.bounds.width - padding * 2

        // Title
        let titleLabel = createLabel(text: title, fontSize: 15, weight: .medium)
        titleLabel.frame = NSRect(x: padding, y: yOffset, width: 200, height: 24)
        contentView.addSubview(titleLabel)

        // Value Label
        let valueLabel = NSTextField(frame: NSRect(x: contentView.bounds.width - padding - 90, y: yOffset + 2, width: 90, height: 22))
        valueLabel.isEditable = false
        valueLabel.isBordered = false
        valueLabel.backgroundColor = .clear
        valueLabel.textColor = NSColor(white: 0.75, alpha: 1.0)
        valueLabel.alignment = .right
        valueLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        contentView.addSubview(valueLabel)

        yOffset += 30

        // Slider
        let slider = NSSlider(frame: NSRect(x: padding, y: yOffset, width: contentWidth, height: 30))
        slider.minValue = minValue
        slider.maxValue = maxValue
        slider.target = self
        slider.action = action
        slider.isContinuous = true
        contentView.addSubview(slider)
        yOffset += 40

        return (slider, valueLabel)
    }

    private func createLabel(text: String, fontSize: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let label = NSTextField()
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.textColor = NSColor(white: 0.85, alpha: 1.0)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        return label
    }

    private func createDivider(y: CGFloat, width: CGFloat) -> NSBox {
        let padding: CGFloat = 20
        let divider = NSBox(frame: NSRect(x: padding, y: y - 1, width: width, height: 1))
        divider.boxType = .separator
        return divider
    }

    // MARK: - Populate Values

    private func populateWithCurrentValues() {
        intensitySlider.doubleValue = Double(currentParameters.intensity)
        intensityLabel.stringValue = String(format: "%.2f", currentParameters.intensity)

        speedSlider.doubleValue = Double(currentParameters.speed)
        speedLabel.stringValue = String(format: "%.2f", currentParameters.speed)

        depthSlider.doubleValue = Double(currentParameters.depth)
        depthLabel.stringValue = String(format: "%.2f", currentParameters.depth)

        contrastSlider.doubleValue = Double(currentParameters.contrast)
        contrastLabel.stringValue = String(format: "%.2f", currentParameters.contrast)

        colorTempSlider.doubleValue = Double(currentParameters.colorTemperature)
        colorTempLabel.stringValue = "\(Int(currentParameters.colorTemperature))K"

        glowSlider.doubleValue = Double(currentParameters.glow)
        glowLabel.stringValue = String(format: "%.2f", currentParameters.glow)

        typingReactivitySlider.doubleValue = Double(currentParameters.typingReactivityStrength)
        typingReactivityLabel.stringValue = String(format: "%.2f", currentParameters.typingReactivityStrength)
    }

    func updateCurrentPreset(presetName: String) {
        guard let popUpButton = presetPopUpButton else {
            // UI not loaded yet, will be set during populateWithCurrentValues()
            return
        }

        if let index = allPresets.firstIndex(where: { $0.name == presetName }) {
            popUpButton.selectItem(at: index)
        }
    }

    // MARK: - Actions

    @objc private func presetChanged(_ sender: NSPopUpButton) {
        guard let selectedPreset = allPresets[safe: sender.indexOfSelectedItem] else { return }

        currentParameters = selectedPreset.defaultParameters
        populateWithCurrentValues()

        onPresetChanged?(selectedPreset)
        SettingsManager.shared.saveParameters(currentParameters)
    }

    @objc private func intensityChanged(_ sender: NSSlider) {
        currentParameters.intensity = Float(sender.doubleValue)
        intensityLabel.stringValue = String(format: "%.2f", currentParameters.intensity)
        notifyParametersChanged()
    }

    @objc private func speedChanged(_ sender: NSSlider) {
        currentParameters.speed = Float(sender.doubleValue)
        speedLabel.stringValue = String(format: "%.2f", currentParameters.speed)
        notifyParametersChanged()
    }

    @objc private func depthChanged(_ sender: NSSlider) {
        currentParameters.depth = Float(sender.doubleValue)
        depthLabel.stringValue = String(format: "%.2f", currentParameters.depth)
        notifyParametersChanged()
    }

    @objc private func contrastChanged(_ sender: NSSlider) {
        currentParameters.contrast = Float(sender.doubleValue)
        contrastLabel.stringValue = String(format: "%.2f", currentParameters.contrast)
        notifyParametersChanged()
    }

    @objc private func colorTempChanged(_ sender: NSSlider) {
        currentParameters.colorTemperature = Float(sender.doubleValue)
        colorTempLabel.stringValue = "\(Int(currentParameters.colorTemperature))K"
        notifyParametersChanged()
    }

    @objc private func glowChanged(_ sender: NSSlider) {
        currentParameters.glow = Float(sender.doubleValue)
        glowLabel.stringValue = String(format: "%.2f", currentParameters.glow)
        notifyParametersChanged()
    }

    @objc private func typingReactivityChanged(_ sender: NSSlider) {
        currentParameters.typingReactivityStrength = Float(sender.doubleValue)
        typingReactivityLabel.stringValue = String(format: "%.2f", currentParameters.typingReactivityStrength)
        notifyParametersChanged()
    }

    @objc private func resetToDefaults() {
        guard let selectedPreset = allPresets[safe: presetPopUpButton.indexOfSelectedItem] else { return }

        currentParameters = selectedPreset.defaultParameters
        populateWithCurrentValues()
        notifyParametersChanged()

        print("Reset to defaults for preset: \(selectedPreset.name)")
    }

    @objc private func closePanel() {
        onClose?()
    }

    private func notifyParametersChanged() {
        onParametersChanged?(currentParameters)
        SettingsManager.shared.saveParameters(currentParameters)
    }
}

// MARK: - Flipped View for Top-Down Layout

class FlippedView: NSView {
    override var isFlipped: Bool {
        return true  // Makes y=0 at the top instead of bottom
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
