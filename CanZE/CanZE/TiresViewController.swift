//
//  TiresViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 10/02/21.
//

import UIKit

class TiresViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_TireFL: UILabel!
    @IBOutlet var text_TireFLState: UILabel!
    @IBOutlet var text_TireFLPressure: UILabel!
    @IBOutlet var text_TireFLId: UITextField!

    @IBOutlet var label_TireFR: UILabel!
    @IBOutlet var text_TireFRState: UILabel!
    @IBOutlet var text_TireFRPressure: UILabel!
    @IBOutlet var text_TireFRId: UITextField!

    @IBOutlet var help_PressuresMbar: UILabel!

    @IBOutlet var label_TireRL: UILabel!
    @IBOutlet var text_TireRLState: UILabel!
    @IBOutlet var text_TireRLPressure: UILabel!
    @IBOutlet var text_TireRLId: UITextField!

    @IBOutlet var label_TireRR: UILabel!
    @IBOutlet var text_TireRRState: UILabel!
    @IBOutlet var text_TireRRPressure: UILabel!
    @IBOutlet var text_TireRRId: UITextField!

    @IBOutlet var label_TireSpdPresMisadaption: UILabel!
    @IBOutlet var text_TireSpdPresMisadaption: UILabel!

    @IBOutlet var button_TiresRead: UIButton!
    @IBOutlet var button_TiresWrite: UIButton!

    @IBOutlet var button_TiresSaveA: UIButton!
    @IBOutlet var button_TiresLoadA: UIButton!

    @IBOutlet var button_TiresSaveB: UIButton!
    @IBOutlet var button_TiresLoadB: UIButton!

    @IBOutlet var button_TiresSwap: UIButton!

    let val_TireSpdPresMisadaption = [NSLocalizedString("default_Ok", comment: ""), NSLocalizedString("default_NotOk", comment: "")]
    let val_TireState = Globals.localizableFromPlist?.value(forKey: "list_TireStatus") as? [String]
    let val_Unavailable = NSLocalizedString("default_Dash", comment: "")

//    private int baseColor;
//    @ColorInt private int alarmColor;
    var previousState = -2 // uninitialized
    var ecu: Ecu!
    var ecuFromId: Int!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_tires", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        label_TireFL.text = NSLocalizedString("label_TireFL", comment: "")
        text_TireFLState.text = "-"
        text_TireFLPressure.text = "-"
        text_TireFLId.text = "000000"

        label_TireFR.text = NSLocalizedString("label_TireFR", comment: "")
        text_TireFRState.text = "-"
        text_TireFRPressure.text = "-"
        text_TireFRId.text = "000000"

        help_PressuresMbar.text = NSLocalizedString("help_PressuresMbar", comment: "")

        label_TireRL.text = NSLocalizedString("label_TireRL", comment: "")
        text_TireRLState.text = "-"
        text_TireRLPressure.text = "-"
        text_TireRLId.text = "000000"

        label_TireRR.text = NSLocalizedString("label_TireRR", comment: "")
        text_TireRRState.text = "-"
        text_TireRRPressure.text = "-"
        text_TireRRId.text = "000000"

        label_TireSpdPresMisadaption.text = NSLocalizedString("label_TireSpdPresMisadaption", comment: "")
        text_TireSpdPresMisadaption.text = "-"

        button_TiresRead.setTitle(NSLocalizedString("button_Tires_read", comment: "").uppercased(), for: .normal)
        button_TiresWrite.setTitle(NSLocalizedString("button_Tires_write", comment: "").uppercased(), for: .normal)

        button_TiresSaveA.setTitle(NSLocalizedString("SAVE TO A", comment: ""), for: .normal)
        button_TiresLoadA.setTitle(NSLocalizedString("LOAD FROM A", comment: ""), for: .normal)

        button_TiresSaveB.setTitle(NSLocalizedString("SAVE TO B", comment: ""), for: .normal)
        button_TiresLoadB.setTitle(NSLocalizedString("LOAD FROM B", comment: ""), for: .normal)

        button_TiresSwap.setTitle(NSLocalizedString("SWAP FRONT REAR", comment: ""), for: .normal)

        ecu = Ecus.getInstance.getByMnemonic("BCM")
        ecuFromId = (ecu == nil) ? 0 : ecu.fromId

        /*
         TypedValue typedValue = new TypedValue();
         Resources.Theme theme = this.getTheme();
         theme.resolveAttribute(R.attr.colorButtonNormal, typedValue, true);
         baseColor = typedValue.data;
         boolean dark = ((baseColor & 0xff0000) <= 0xa00000);
         alarmColor = dark ? baseColor + 0x200000 : baseColor - 0x00002020;
         */

        tpmsState(-1) // initialize to "no TPMS, but don't Toast that". This ensures disabled fields, also after a rotate
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(decoded(notification:)), name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endQueue2), name: Notification.Name("endQueue2"), object: nil)

        startQueue()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("endQueue2"), object: nil)
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

    func startQueue() {
        if !Globals.shared.deviceIsConnected || !Globals.shared.deviceIsInitialized {
            DispatchQueue.main.async {
                self.view.makeToast("_device not connected")
            }
            return
        }

        queue2 = []

        addField(Sid.TpmsState, intervalMs: 1000)
        addField(Sid.TireSpdPresMisadaption, intervalMs: 6000)
        addField(Sid.TireFLState, intervalMs: 6000)
        addField(Sid.TireFLPressure, intervalMs: 6000)
        addField(Sid.TireFRState, intervalMs: 6000)
        addField(Sid.TireFRPressure, intervalMs: 6000)
        addField(Sid.TireRLState, intervalMs: 6000)
        addField(Sid.TireRLPressure, intervalMs: 6000)
        addField(Sid.TireRRState, intervalMs: 6000)
        addField(Sid.TireRRPressure, intervalMs: 6000)

        startQueue2()
    }

    @objc func endQueue2() {
        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let val = Globals.shared.fieldResultsDouble[sid!]

        if val != nil {
            DispatchQueue.main.async {
                /*   switch sid {
                                             // get the text field
                                        case Sid.TpmsState:
                                            tpmsState (intValue);
                                            tv = null;
                                            break;
                                        case Sid.TireSpdPresMisadaption:
                                            tv = findViewById(R.id.text_TireSpdPresMisadaption);
                                            color = 0; // don't set color
                                            value = val_TireSpdPresMisadaption[intValue];
                                            break;
                                        case Sid.TireFLState:
                                            if (intValue < 0 || intValue > 6) return;
                                            tv = findViewById(R.id.text_TireFLState);
                                            if (intValue > 1) color = alarmColor;
                                            value = val_TireState != null ? val_TireState[intValue] : "";
                                            break;
                                        case Sid.TireFLPressure:
                                            tv = findViewById(R.id.text_TireFLPressure);
                                            value = (intValue >= 3499) ? val_Unavailable : ("" + intValue);
                                            break;
                                        case Sid.TireFRState:
                                            if (intValue < 0 || intValue > 6) return;
                                            tv = findViewById(R.id.text_TireFRState);
                                            if (intValue > 1) color = alarmColor;
                                            value = val_TireState != null ? val_TireState[intValue] : "";
                                            break;
                                        case Sid.TireFRPressure:
                                            tv = findViewById(R.id.text_TireFRPressure);
                                            value = (intValue >= 3499) ? val_Unavailable : ("" + intValue);
                                            break;
                                        case Sid.TireRLState:
                                            if (intValue < 0 || intValue > 6) return;
                                            tv = findViewById(R.id.text_TireRLState);
                                            if (intValue > 1) color = alarmColor;
                                            value = val_TireState != null ? val_TireState[intValue] : "";
                                            break;
                                        case Sid.TireRLPressure:
                                            tv = findViewById(R.id.text_TireRLPressure);
                                            value = (intValue >= 3499) ? val_Unavailable : ("" + intValue);
                                            break;
                                        case Sid.TireRRState:
                                            if (intValue < 0 || intValue > 6) return;
                                            tv = findViewById(R.id.text_TireRRState);
                                            if (intValue > 1) color = alarmColor;
                                            value = val_TireState != null ? val_TireState[intValue] : "";
                                            break;
                                        case Sid.TireRRPressure:
                                            tv = findViewById(R.id.text_TireRRPressure);
                                            value = (intValue >= 3499) ? val_Unavailable : ("" + intValue);
                                            break;
                                    }
                                    // set regular new content, all exeptions handled above
                                    if (tv != null) {
                                        tv.setText(value);
                                        if (color != 0) tv.setBackgroundColor(color);
                                    }

                                    tv = findViewById(R.id.textDebug);
                                    tv.setText(fieldId);
                                }
                            });

                 } */
            }
        }
    }

    func tpmsState(_ state: Int) {
        if state == previousState || ecu == nil || ecuFromId == 0 {
            return
        }
        previousState = state
        let isEnabled = (state == 1)

        text_TireFLId.isEnabled = isEnabled
        text_TireFRId.isEnabled = isEnabled
        text_TireRLId.isEnabled = isEnabled
        text_TireRRId.isEnabled = isEnabled

        button_TiresRead.isEnabled = isEnabled
        button_TiresWrite.isEnabled = isEnabled
        button_TiresSaveA.isEnabled = isEnabled
        button_TiresLoadA.isEnabled = isEnabled
        button_TiresSaveB.isEnabled = isEnabled
        button_TiresLoadB.isEnabled = isEnabled
        button_TiresSwap.isEnabled = isEnabled

        // do not use !enabled as a rotate will reinitialize the activity, setting state to -1
        if state == 0 {
            view.makeToast("Your car has no TPMS system")
        } else if state == 1 {
            buttonRead()
        }
    }

    func load(_ set: String?) {
        let idsRead1 = ud.string(forKey: "ids1\(set ?? "")") ?? ""
        let idsRead2 = ud.string(forKey: "ids2\(set ?? "")") ?? ""
        let idsRead3 = ud.string(forKey: "ids3\(set ?? "")") ?? ""
        let idsRead4 = ud.string(forKey: "ids4\(set ?? "")") ?? ""
        text_TireFLId.text = idsRead1
        text_TireFRId.text = idsRead2
        text_TireRRId.text = idsRead3
        text_TireRLId.text = idsRead4
    }

    func save(_ set: String) {
        ud.setValue(text_TireFLId.text, forKey: "ids1\(set)")
        ud.setValue(text_TireFRId.text, forKey: "ids2\(set)")
        ud.setValue(text_TireRLId.text, forKey: "ids3\(set)")
        ud.setValue(text_TireRRId.text, forKey: "ids4\(set)")
        ud.synchronize()
    }

    func buttonRead() {
        view.makeToast("DISABLED")
    }

    /*
     func buttonRead() {
         let idsRead = readTpms()
         // display the fetched values
         text_TireFLId.text = "\(idsRead![0])"
         text_TireFRId.text = "\(idsRead![1])"
         text_TireRRId.text = "\(idsRead![2])"
         text_TireRLId.text = "\(idsRead![3])"
         view.makeToast("TPMS sensors read")
     }

     / *
         // set the two button handlers
         @IBAction func button_TiresRead_() {
             buttonRead()
         }

         @IBAction func button_TiresWrite_() {
             buttonWrite()
         }

         @IBAction func button_TiresLoadA_() {
             load("A")
         }

         @IBAction func button_TiresSaveA_() {
             save("A")
         }

         @IBAction func button_TiresLoadB_() {
             load("B")
         }

         @IBAction func button_TiresSaveB_() {
             save("B")
         }

         @IBAction func button_TiresSwap_() {
             buttonSwap()
         }

         /*
          private void displayId(final int fieldId, final int val) {
              displayId(fieldId, String.format("%06X", val))
          }
           */
         /*
          private void displayId(final int fieldId, final String val) {
              runOnUiThread(new Runnable {
                  @Override
                  public void run {
                      EditText et = findViewById(fieldId)
                      if et != null
                      et.setText(val)
                  }
              })
          }
          */

         /*
          func readTpms() -> [Int]? {
              var idsRead = [0, 0, 0, 0]
              if ecu == nil || ecuFromId == 0 {
                  return nil
              }
              if let frame = Frames.getInstance.getById(id: ecuFromId, responseId: "6171") { // get TPMS ids
                  let message = device.injectRequest(frame) // return result message of last request (get TPMS ids)
                  if message == nil {
                      view.makeToast("Could not read TPMS sensors")
                      return nil
                  }
                  if message.isError() {
                      view.makeToast("Could not read TPMS sensors:" + message.getError())
                      return nil
                  }

                  // process the frame by going through all the containing fields
                  // setting their values and notifying all listeners (there should be none)
                  message.onMessageCompleteEvent()

                  // now process all fields in the frame. Select only the ones we are interested in
                  for field in frame.getAllFields() {
                      switch field.from {
                          case 24: // CodeIdentite(1)_(0) --> Ident code, left front wheel (Wheel 1, set 0)
                              idsRead[0] = Int(field.getValue())
                          case 48: // CodeIdentite(2)_(0) --> Ident code, right front wheel (Wheel 2, set 0)
                              idsRead[1] = Int(field.getValue())
                          case 72: // CodeIdentite(3)_(0) --> Ident code, right rear wheel (Wheel 3, set 0)
                              idsRead[2] = Int(field.getValue())
                          case 96: // CodeIdentite(4)_(0) --> IIdent code, left rear wheel (Wheel 4, set 0)
                              idsRead[3] = Int(field.getValue())
                          default:
                              print("?")
                      }
                  }
                  idsRead = bit23on(idsRead)

              } else {
                  view.makeToast("frame does not exist:" + ecu.getHexFromId + ".6171")
                  return nil
              }
          }

        /*
          private int simpleIntParse(int fieldId) {
              try {
                  Integer.parseInt(simpleStringParse(fieldId), 16)
              } catch (Exception e) {
                  return -1
              }
          }
          */
         /*
          private String simpleStringParse(int fieldId) {
              EditText et = findViewById(fieldId)
              if et != null {
                  return et.getText().toString()
              } else {
                  return "-1"
              }
          }
          */
         /*
          private boolean compareTpms(int[] idsRead, int[] idsWrite) {
              for int i = 0; i < idsRead.length; i++ {
                  if idsRead[i] == 0 return false
                  if idsWrite[i] == 0 return false
                  if idsRead[i] != idsWrite[i] return false
              }
              return true
          }
          */

         /*
             func buttonWrite() {
                 var idsWrite: [Int] = [0, 0, 0, 0]
                 var idsRead: [Int] = [0, 0, 0, 0]

                 idsWrite[0] = Int(text_TireFLId.text) // front left / AVG
                 idsWrite[1] = Int(text_TireFRId.text) // front right / AVD
                 idsWrite[2] = Int(text_TireRRId.text) // back right / ARD
                 idsWrite[3] = Int(text_TireRLId.text) // back left / ARG

                 idsWrite = bit23on(idsWrite)

                 if ecu == nil || ecuFromId == 0 {
                     return
                 }
                 if idsWrite[0] == -1 || idsWrite[1] == -1 || idsWrite[2] == -1 || idsWrite[3] == -1 {
                     view.makeToast("Those are not all valid hex values")
                     return
                 }
                 if idsWrite[0] == 0, idsWrite[1] == 0, idsWrite[2] == 0, idsWrite[3] == 0 {
                     view.makeToast("All values are 0")
                     return
                 }

                 for retries in 0 ..< 3 {
                     // write the values
                     for i in 0 ..< idsWrite.count {
                         if idsWrite[i] != 0 {
                             let frame = Frame(ecuFromId, 0, ecu, String(format: "7b5e%02x%06x", i + 1, idsWrite[i]), [])
                             let message = device.injectRequest(frame)
                             if message == nil {
                                 view.makeToast("Could not write TPMS valve \(i)")
                             } else if message.isError() {
                                 view.makeToast("Could not write TPMS valve \(i):\(message.getError()))")
                             } else if !message.getData().startsWith("7b5e") {
                                 view.makeToast("Could not write TPMS valve \(i):\(message.getData())")
                             } else {
                                 view.makeToast("Wrote TPMS valve \(i)")
                             }
                             try {
                                 Thread.sleep(250)
                             } catch (Exception e) {
                                 // ignore a sleep exception
                             }
                         }
                     }

                     // now read the values
                     idsRead = readTpms()
                     if compareTpms(idsRead, idsWrite) {
                         MainActivity.toast(MainActivity.TOAST_NONE, "TPMS sensors written. Read again to verify")
                         return
                     }
                     try {
                         Thread.sleep(250)
                     } catch (Exception e) {
                         // ignore a sleep exception
                     }
                 }
                 MainActivity.toast(MainActivity.TOAST_NONE, "Failed to write all TPMS sensors")
             }

             func buttonSwap() {
                 int[] ids = new int[4]

                 ids[0] = simpleIntParse(R.id.text_TireFLId) // front left / AVG
                 ids[1] = simpleIntParse(R.id.text_TireFRId) // front right / AVD
                 ids[2] = simpleIntParse(R.id.text_TireRRId) // back right / ARD
                 ids[3] = simpleIntParse(R.id.text_TireRLId) // back left / ARG

                 bit23on(ids)

                 displayId(R.id.text_TireFLId, ids[3])
                 displayId(R.id.text_TireFRId, ids[2])
                 displayId(R.id.text_TireRRId, ids[1])
                 displayId(R.id.text_TireRLId, ids[0])
             }

             func bit23on(_ ids2: [Int]) -> [Int] {
                 var ids = ids2
                 for i in 0 ..< ids.count {
                     ids[i] = 0x800000 | (ids[i] & 0x7fffff)
                 }
                 return ids
             }
      */
      */
          */
}