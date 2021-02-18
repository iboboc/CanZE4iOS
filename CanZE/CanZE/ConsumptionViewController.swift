//
//  ConsumptionViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 04/02/21.
//

import Charts
import UIKit

class ConsumptionViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_WheelTorque: UILabel!
    @IBOutlet var text_wheel_torque: UILabel!
    @IBOutlet var label_InstantConsumption: UILabel!
    @IBOutlet var text_instant_consumption_negative: UILabel!

    @IBOutlet var pb_driver_torque_request: UIProgressView!
    @IBOutlet var MaxBrakeTorque: UIProgressView!
    @IBOutlet var MeanEffectiveAccTorque: UIProgressView!

    @IBOutlet var pb_instant_consumption_negative: UIProgressView!
    @IBOutlet var pb_instant_consumption_positive: UIProgressView!

    @IBOutlet var lblGraphTitle1: UILabel!
    @IBOutlet var lblGraphValue1a: UILabel!
    @IBOutlet var lblGraphValue1b: UILabel!
    @IBOutlet var chartView1: LineChartView!

    @IBOutlet var lblGraphTitle2: UILabel!
    @IBOutlet var lblGraphValue2a: UILabel!
    @IBOutlet var lblGraphValue2b: UILabel!
    @IBOutlet var chartView2: LineChartView!

    @IBOutlet var lblGraphTitle3: UILabel!
    @IBOutlet var lblGraphValue3a: UILabel!
    @IBOutlet var lblGraphValue3b: UILabel!
    @IBOutlet var chartView3: LineChartView!

    var chartEntries1a = [ChartDataEntry]()
    var chartEntries1b = [ChartDataEntry]()
    var line1a: LineChartDataSet!
    var line1b: LineChartDataSet!

    var chartEntries2a = [ChartDataEntry]()
    var chartEntries2b = [ChartDataEntry]()
    var line2a: LineChartDataSet!
    var line2b: LineChartDataSet!

    var chartEntries3a = [ChartDataEntry]()
    var chartEntries3b = [ChartDataEntry]()
    var line3a: LineChartDataSet!
    var line3b: LineChartDataSet!

    var coasting_Torque = 0
    var driverBrakeWheel_Torque_Request = 0
    var posTorque = 0
    var negTorque = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_consumption", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        label_WheelTorque.text = NSLocalizedString("label_WheelTorque", comment: "")
        text_wheel_torque.text = "-"
        label_InstantConsumption.text = NSLocalizedString("label_InstantConsumption", comment: "")
        text_instant_consumption_negative.text = "-"

        lblGraphTitle1.text = NSLocalizedString("graph_PowerSoc", comment: "")
        lblGraphValue1a.text = "-"
        lblGraphValue1a.textColor = .purple
        lblGraphValue1b.text = "-"

        lblGraphTitle2.text = NSLocalizedString("graph_SpeedConsumption", comment: "")
        lblGraphValue2a.text = "-"
        lblGraphValue2a.textColor = UIColor(rgb: 0x008a1d)
        lblGraphValue2b.text = "-"

        lblGraphTitle3.text = NSLocalizedString("_Delta with reality (km), Range (km)", comment: "")
        lblGraphValue3a.text = "-"
        lblGraphValue3b.text = "-"

        initChart1()
        initChart2()
        initChart3()

        // init progressview
        pb_driver_torque_request.trackImage = UIImage(view: GradientViewDecel(frame: pb_driver_torque_request.bounds))
        pb_driver_torque_request.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        pb_driver_torque_request.progressTintColor = view.backgroundColor
        pb_driver_torque_request.setProgress(1, animated: false)

        MeanEffectiveAccTorque.trackImage = UIImage(view: GradientViewAccel(frame: MeanEffectiveAccTorque.bounds)).withHorizontallyFlippedOrientation()
        MeanEffectiveAccTorque.transform = CGAffineTransform(scaleX: -1.0, y: -1.0)
        MeanEffectiveAccTorque.progressTintColor = view.backgroundColor
        MeanEffectiveAccTorque.setProgress(1, animated: false)

        MaxBrakeTorque.trackImage = UIImage(view: GradientViewDecelAim(frame: MaxBrakeTorque.bounds))
        MaxBrakeTorque.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        MaxBrakeTorque.progressTintColor = view.backgroundColor
        MaxBrakeTorque.setProgress(1, animated: false)

        pb_instant_consumption_negative.trackImage = UIImage(view: GradientViewDecel(frame: pb_instant_consumption_negative.bounds))
        pb_instant_consumption_negative.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        pb_instant_consumption_negative.progressTintColor = view.backgroundColor
        pb_instant_consumption_negative.setProgress(1, animated: false)

        pb_instant_consumption_positive.trackImage = UIImage(view: GradientViewAccel(frame: pb_instant_consumption_positive.bounds)).withHorizontallyFlippedOrientation()
        pb_instant_consumption_positive.transform = CGAffineTransform(scaleX: -1.0, y: -1.0)
        pb_instant_consumption_positive.progressTintColor = view.backgroundColor
        pb_instant_consumption_positive.setProgress(1, animated: false)

        // TEST
        /*
                var t: Float = 0.0
                var senso = "su"
                Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { _ in

                    if t > 1 {
                        senso = "giu"
                        t = 1.0
                    }
                    if t < 0 {
                        senso = "su"
                        t = 0.0
                    }

                    if senso == "su" {
                        t += 0.0125
                    } else {
                        t -= 0.0125
                    }

                    self.pb_driver_torque_request.setProgress(1.0 - t, animated: false)
                    self.MaxBrakeTorque.setProgress(1.0 - t, animated: false)
                    self.pb_instant_consumption_negative.setProgress(1.0 - t, animated: false)
                    self.pb_instant_consumption_positive.setProgress(1.0 - t, animated: false)
                    self.MeanEffectiveAccTorque.setProgress(1.0 - t, animated: false)
                }
         */
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(decoded(notification:)), name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endQueue2), name: Notification.Name("endQueue2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(autoInit2), name: Notification.Name("autoInit"), object: nil)

        startQueue()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("endQueue2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("autoInit"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc func updateDebugLabel(notification: Notification) {
        let dic = notification.object as? [String: String]
        DispatchQueue.main.async {
            self.lblDebug.text = dic?["debug"]
        }
        debug((dic?["debug"])!)
    }

    override func startQueue() {
        if !Globals.shared.deviceIsConnected || !Globals.shared.deviceIsInitialized {
            DispatchQueue.main.async {
                self.view.makeToast("_device not connected")
            }
            return
        }

        queue2 = []

        addField(Sid.TotalPositiveTorque, intervalMs: 0)
        addField(Sid.TotalNegativeTorque, intervalMs: 0)
        addField_(Sid.TotalPotentialResistiveWheelsTorque, intervalMs: 7200)
        addField(Sid.Instant_Consumption, intervalMs: 0)

        addField(Sid.DcPowerOut, intervalMs: 0)
        addField(Sid.UserSoC, intervalMs: 0)

        addField(Sid.RealSpeed, intervalMs: 0)
        addField("800.6100.24", intervalMs: 0)
        addField("800.6104.24", intervalMs: 0)

        startQueue2()
    }

    @objc func endQueue2() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        startQueue()
//        }
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let val = Globals.shared.fieldResultsDouble[sid!]
        if val != nil && !val!.isNaN {
            DispatchQueue.main.async {
                switch sid {
                case Sid.TotalPositiveTorque:
                    self.posTorque = Int(val!)
                    let progress = Float(val!) / 2048.0
                    self.MeanEffectiveAccTorque.setProgress(1 - progress, animated: false)
                case Sid.TotalNegativeTorque:
                    let field = Fields.getInstance.fieldsBySid[sid!]
                    self.negTorque = Int(val!)
                    self.text_wheel_torque.text = "\(self.posTorque - self.negTorque) \(field?.unit ?? "")"
                    let progress = Float(val!) / 1536.0
                    self.pb_driver_torque_request.setProgress(1 - progress, animated: false)
                case Sid.TotalPotentialResistiveWheelsTorque:
                    let tprwt = -Int(val!)
                    let progress = tprwt < 2047 ? Float(tprwt) : 10 / 1536.0
                    self.MaxBrakeTorque.setProgress(1 - progress, animated: false)
                case Sid.Instant_Consumption:
                    let field = Fields.getInstance.fieldsBySid[sid!]
                    let consumptionInt = Int(val!)

                    // progress bars are rescaled to miles by the layout
                    var progress = -Float(min(0, consumptionInt)) / 150.0
                    self.pb_instant_consumption_negative.setProgress(1 - progress, animated: false)

                    progress = Float(max(0, consumptionInt)) / 150.0
                    self.pb_instant_consumption_positive.setProgress(1 - progress, animated: false)

                    if !Globals.shared.milesMode {
                        self.text_instant_consumption_negative.text = "\(consumptionInt) \(field!.unit!)"
                    } else if val != 0.0 { // consumption is now in kWh/100mi, so rescale progress bar
                        // display the value in imperial format (100 / consumption, meaning mi/kwh)
                        self.text_instant_consumption_negative.text = String(format: "%.2f \(NSLocalizedString("unit_ConsumptionMiAlt", comment: ""))", 100.0 / val!)
                    } else {
                        self.text_instant_consumption_negative.text = "-"
                    }
                case Sid.DcPowerOut:
                    self.lblGraphValue1a.text = String(format: "%.0f", val!)
                    var add = true
                    if self.chartEntries1a.count > 0 {
                        let last = self.chartEntries1a.last
                        if last!.x + 5 > Date().timeIntervalSince1970 {
                            add = false
                        }
                    }
                    if add {
                        self.chartEntries1a.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                        self.updateChart1()
                    }
                case Sid.UserSoC:
                    self.lblGraphValue1b.text = String(format: "%.2f", val!)
                    var add = true
                    if self.chartEntries1b.count > 0 {
                        let last = self.chartEntries1b.last
                        if last!.x + 5 > Date().timeIntervalSince1970 {
                            add = false
                        }
                    }
                    if add {
                        self.chartEntries1b.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                        self.updateChart1()
                    }
                case Sid.RealSpeed:
                    self.lblGraphValue2a.text = String(format: "%.2f", val!)
                    var add = true
                    if self.chartEntries2a.count > 0 {
                        let last = self.chartEntries2a.last
                        if last!.x + 5 > Date().timeIntervalSince1970 {
                            add = false
                        }
                    }
                    if add {
                        self.chartEntries2a.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                        self.updateChart2()
                    }
                case "800.6104.24":
                    self.lblGraphValue2b.text = String(format: "%.1f", val!)
                    var add = true
                    if self.chartEntries2b.count > 0 {
                        let last = self.chartEntries2b.last
                        if last!.x + 5 > Date().timeIntervalSince1970 {
                            add = false
                        }
                    }
                    if add {
                        self.chartEntries2b.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                        self.updateChart2()
                    }
                case "800.6107.24":
                    self.lblGraphValue3a.text = String(format: "%.1f", val!)
                    var add = true
                    if self.chartEntries3a.count > 0 {
                        let last = self.chartEntries3a.last
                        if last!.x + 5 > Date().timeIntervalSince1970 {
                            add = false
                        }
                    }
                    if add {
                        self.chartEntries3a.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                        self.updateChart3()
                    }
                case Sid.RangeEstimate:
                    self.lblGraphValue3b.text = String(format: "%.1f", val!)
                    var add = true
                    if self.chartEntries3b.count > 0 {
                        let last = self.chartEntries3b.last
                        if last!.x + 5 > Date().timeIntervalSince1970 {
                            add = false
                        }
                    }
                    if add {
                        self.chartEntries3b.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                        self.updateChart3()
                    }
                default:
                    print("unknown sid \(sid!)")
                }
            }
        }
    }

    func initChart1() {
        chartView1.legend.enabled = false

        let xAxis = chartView1.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        //        xAxis.labelRotationAngle = -45.0
        // chartView1.rightAxis.enabled = false

        let yAxisLeft = chartView1.leftAxis
        yAxisLeft.axisMinimum = -30
        yAxisLeft.axisMaximum = 70

        line1a = LineChartDataSet(entries: chartEntries1a, label: nil)
        //        line1.lineWidth = 0
        line1a.drawCirclesEnabled = false
        line1a.drawValuesEnabled = false
        line1a.lineWidth = 5.0
//        line1a.colors = [.purple]

        let gradientColors1a = [ChartColorTemplates.colorFromString("#cc00ff").cgColor,
                                ChartColorTemplates.colorFromString("#3ee9ff").cgColor,
                                ChartColorTemplates.colorFromString("#008a1d").cgColor,
                                ChartColorTemplates.colorFromString("#ffaa17").cgColor,
                                ChartColorTemplates.colorFromString("#FF0000").cgColor]
        let gradient1a = CGGradient(colorsSpace: nil, colors: gradientColors1a as CFArray, locations: [0.0, 0.3, 0.5, 0.66, 1.0])
        line1a.fill = Fill.fillWithLinearGradient(gradient1a!, angle: 90)
        line1a.fillAlpha = 1
        line1a.drawFilledEnabled = true

        let yAxisRight = chartView1.rightAxis
        yAxisRight.axisMinimum = 0
        yAxisRight.axisMaximum = 100

        line1b = LineChartDataSet(entries: chartEntries1b, label: nil)
        line1b.axisDependency = .right
        //        line2.lineWidth = 0
        line1b.drawCirclesEnabled = false
        line1b.drawValuesEnabled = false
        line1b.colors = [.red]
//        line1b.lineWidth = 2.0

//        let gradientColors1b = [ChartColorTemplates.colorFromString("#cc00ff").cgColor,
//                                ChartColorTemplates.colorFromString("#3ee9ff").cgColor,
//                                ChartColorTemplates.colorFromString("#008a1d").cgColor,
//                                ChartColorTemplates.colorFromString("#ffaa17").cgColor,
//                                ChartColorTemplates.colorFromString("#FF0000").cgColor]
//        let gradient1b = CGGradient(colorsSpace: nil, colors: gradientColors1b as CFArray, locations: [0.0, 0.3, 0.5, 0.66, 1.0])
//        line1b.fill = Fill.fillWithLinearGradient(gradient1b!, angle: 90)
//        line1b.fillAlpha = 1
//        line1b.drawFilledEnabled = true

        chartView1.data = LineChartData(dataSets: [line1a, line1b])
    }

    func initChart2() {
        chartView2.legend.enabled = false

        let xAxis = chartView2.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0
//        chartView2.rightAxis.enabled = false

        let yAxisLeft = chartView2.leftAxis
        yAxisLeft.axisMinimum = 0
        yAxisLeft.axisMaximum = 160

        line2a = LineChartDataSet(entries: chartEntries2a, label: nil)
//        line3.lineWidth = 0
        line2a.drawCirclesEnabled = false
        line2a.drawValuesEnabled = false
        let gradientColors2a = [ChartColorTemplates.colorFromString("#008a1d").cgColor,
                                ChartColorTemplates.colorFromString("#ffaa17").cgColor,
                                ChartColorTemplates.colorFromString("#FF0000").cgColor,
                                ChartColorTemplates.colorFromString("#cc00ff").cgColor]
        let gradient2a = CGGradient(colorsSpace: nil, colors: gradientColors2a as CFArray, locations: [0.0, 0.35, 0.65, 1.0])
        line2a.fill = Fill.fillWithLinearGradient(gradient2a!, angle: 90)
        line2a.fillAlpha = 1
        line2a.drawFilledEnabled = true

        let yAxisRight = chartView2.rightAxis
        yAxisRight.axisMinimum = 0
        yAxisRight.axisMaximum = 40

        line2b = LineChartDataSet(entries: chartEntries2b, label: nil)
        line2b.axisDependency = .right
        line2b.drawCirclesEnabled = false
        line2b.drawValuesEnabled = false

//        let gradientColors4 = [ChartColorTemplates.colorFromString("#ff0000").cgColor,
//                               ChartColorTemplates.colorFromString("#00ff00").cgColor,
//                               ChartColorTemplates.colorFromString("#0000ff").cgColor,
//                               ChartColorTemplates.colorFromString("#ffff00").cgColor,
//                               ChartColorTemplates.colorFromString("#00ffff").cgColor,
//                               ChartColorTemplates.colorFromString("#ff00ff").cgColor,
//                               ChartColorTemplates.colorFromString("#000000").cgColor,
//                               ChartColorTemplates.colorFromString("#808080").cgColor]
//        let gradient4 = CGGradient(colorsSpace: nil, colors: gradientColors4 as CFArray, locations: [0.0, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0])
//        line4.fill = Fill.fillWithLinearGradient(gradient4!, angle: 90)
//        line4.fillAlpha = 1
//        line4.drawFilledEnabled = true

        chartView2.data = LineChartData(dataSets: [line2a, line2b])
    }

    func initChart3() {
        chartView3.legend.enabled = false

        let xAxis = chartView3.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0
//        chartView3.rightAxis.enabled = false

        let yAxisLeft = chartView3.leftAxis
        yAxisLeft.axisMinimum = -12
        yAxisLeft.axisMaximum = 12

        line3a = LineChartDataSet(entries: chartEntries3a, label: nil)
        line3a.drawCirclesEnabled = false
        line3a.drawValuesEnabled = false

        let yAxisRight = chartView3.rightAxis
        yAxisRight.axisMinimum = 0
        yAxisRight.axisMaximum = 180

        line3b = LineChartDataSet(entries: chartEntries3b, label: nil)
        line3b.axisDependency = .right
        line3b.drawCirclesEnabled = false
        line3b.drawValuesEnabled = false

        chartView3.data = LineChartData(dataSets: [line3a, line3b])
    }

    func updateChart1() {
        line1a.replaceEntries(chartEntries1a)
        line1b.replaceEntries(chartEntries1b)
        chartView1.data = LineChartData(dataSets: [line1a, line1b])
    }

    func updateChart2() {
        line2a.replaceEntries(chartEntries2a)
        line2b.replaceEntries(chartEntries2b)
        chartView2.data = LineChartData(dataSets: [line2a, line2b])
    }

    func updateChart3() {
        line3a.replaceEntries(chartEntries3a)
        line3b.replaceEntries(chartEntries3b)
        chartView3.data = LineChartData(dataSets: [line3a, line3b])
    }

    class TimestampAxis: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            var s = ""
            let df = DateFormatter()
            df.dateStyle = .none
            df.timeStyle = .short
            let d = Date(timeIntervalSince1970: value)
            s = df.string(from: d)
            return s
        }
    }
}
