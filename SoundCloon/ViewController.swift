//
//  ViewController.swift
//  SoundCloon
//
//  Created by Naman Kalkhuria on 7/21/20.
//  Copyright © 2020 Naman Kalkhuria. All rights reserved.
//

import Cocoa
import AudioKit
import AudioKitUI

class CustomSliderCell: NSSliderCell {

    let bar: NSImage

    required init(coder aDecoder: NSCoder) {
        self.bar = NSImage(named: "bar")!
        super.init(coder: aDecoder)
    }

    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        var rect = aRect
        rect.size = NSSize(width: rect.width, height: 3)
        self.bar.draw(in: rect)
        super.drawBar(inside: rect, flipped: flipped)
    }

}

class ViewController: NSViewController {
    let sequencer = AKAppleSequencer()//2
    let sequenceLength = AKDuration(beats: 8.0)
    
    @IBOutlet var WaveView: NSStackView!
    @IBOutlet var ADSRGraphView: NSStackView!
    @IBOutlet var oscLabel: NSTextField!
    @IBOutlet var BpmLabel: NSTextField!
    @IBOutlet var Filter: NSSlider!
    @IBOutlet var MabSlider: MABSlider!
    
    var fmWithADSR:AKMorphingOscillatorBank = AKMorphingOscillatorBank(waveformArray: [
        AKTable(.sine),
        AKTable(.sawtooth),
        AKTable(.triangle),
        AKTable(.square)]);
    
    
    var filter:AKBandPassButterworthFilter = AKBandPassButterworthFilter();
    var delay:AKDelay = AKDelay();
    var reverb:AKReverb = AKReverb();
    var plot: AKOutputWaveformPlot = AKOutputWaveformPlot();
    
    
    var scaleSelected:String = "Am";
    var chordNotes: Dictionary<String, Array <Int>> = [
        "Am": [69, 72, 76],
        "G": [67, 71, 74],
        "C": [60, 64, 67],
    ]
    var chordProgressionBank : Dictionary<String, Array<String>> = [
        "Am": ["Am", "C"],
        "C": ["C", "G"]
    ]
    
    
    @IBAction func OscChanged(_ sender: NSSlider) {
        let square = AKTable(.square, count: 256)
        let triangle = AKTable(.triangle, count: 256)
        let sine = AKTable(.sine, count: 256)
        let sawtooth = AKTable(.sawtooth, count: 256)
        
        var waveform:AKTable;
        var waveformName:String;
        var index:Double;
        
        if (sender.integerValue < 25) {
            waveform = sine;
            waveformName = "sine";
            index = 0.0;
            
        } else if (sender.integerValue < 50) {
            waveform = triangle;
            waveformName = "triangle"
            index = 1.0;
        } else if (sender.integerValue < 75) {
            waveform = sawtooth;
            waveformName = "sawtooth"
            index = 2.0;
        } else {
            waveform = square;
            waveformName = "square"
            index = 3.0;
        }
        
        self.oscLabel.stringValue = waveformName;
        fmWithADSR.index = index;
    }
    
    @IBAction func AttackChanged(_ sender: NSSlider) {
        self.fmWithADSR.attackDuration = Double(sender.integerValue)/100.00;
    }
    
    @IBAction func DecayChanged(_ sender: NSSlider) {
        self.fmWithADSR.decayDuration = Double(sender.integerValue)/100.00;
    }
    
    
    @IBAction func SustainChanged(_ sender: NSSlider) {
        self.fmWithADSR.sustainLevel = Double(sender.integerValue)/100.00;
    }
    
    
    @IBAction func ReleaseChanged(_ sender: NSSlider) {
        self.fmWithADSR.releaseDuration = Double(sender.integerValue)/100.00;
    }
    
    @IBAction func DelayChanged(_ sender: NSSlider) {
        self.delay.dryWetMix = sender.integerValue/100;
    }
    
    @IBAction func ReverbChanged(_ sender: NSSlider) {
        self.reverb.dryWetMix = sender.integerValue/100;
    }
    
    @IBAction func AmSelected(_ sender: Any) {
        self.scaleSelected = "Am";
    }
    
    @IBAction func CSelected(_ sender: NSButton) {
        self.scaleSelected = "C";
//       self.plot.resume();
    }
    
    @IBAction func DSelected(_ sender: NSButton) {
        self.scaleSelected = "D";
    }
    
    @IBAction func EmSelected(_ sender: NSButton) {
        self.scaleSelected = "Em";
    }
    
    
    @IBAction func GmSelected(_ sender: NSButton) {
        self.scaleSelected = "Gm";
    }
    
    @IBAction func BSelected(_ sender: NSButton) {
        self.scaleSelected = "B";
    }
    
    @IBAction func BpmSelected(_ sender: NSSlider) {
        self.BpmLabel.stringValue = String(sender.integerValue);
        self.sequencer.setTempo(sender.doubleValue);
    }
    
    
    @IBAction func FilterChanged(_ sender: NSSlider) {
        var centerFrequency = sender.doubleValue*10.00;
        
        self.filter.centerFrequency = centerFrequency;
    }
    
    @IBAction func stopSynth(_ sender: Any) {
        self.sequencer.stop();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func setupPlot() {
        let frame = CGRect(x: 0.0, y: 0.0, width: 440, height: 330)
        self.plot = AKOutputWaveformPlot(frame: frame)
        
        plot.plotType = .rolling
        plot.backgroundColor = AKColor.clear
        plot.shouldCenterYAxis = true
        
        
        self.WaveView.addArrangedSubview(self.plot);
    }
    
    func setupSynth() -> AKMIDINode{
        let midiNode = AKMIDINode(node: self.fmWithADSR)
                
        self.delay = AKDelay(midiNode)
        self.delay.time = 0.1;
        self.delay.feedback = 0.1 ;
        self.delay.dryWetMix = 0.1 ;
        
        self.reverb = AKReverb(self.delay)
        self.reverb.loadFactoryPreset(.cathedral)
        self.reverb.dryWetMix = 0.5
        
        self.filter = AKBandPassButterworthFilter(self.reverb)
        self.filter.centerFrequency = 5_00;
        self.filter.bandwidth = 600 // Cents
        self.filter.rampDuration = 1.0
        

        return midiNode;
    }
    
    func setupSequencer(midiNode: AKMIDINode) {
        let track = sequencer.newTrack()
        sequencer.setLength(sequenceLength)
//        self.generateSequence() 
        
        
        AudioKit.output = self.filter;
        self.setupPlot();
        
        do {
            try? AudioKit.start()
        } catch{
               
        }
           
        track?.setMIDIOutput(midiNode.midiIn);
        sequencer.setTempo(20.0)
        sequencer.enableLooping()
        sequencer.play()
    }
    
    func generateSequence() {
        
          let stepSize: Float = 1/8 //1
          sequencer.tracks[0].clear() //2
          let numberOfSteps = Int(Float(sequenceLength.beats)/stepSize)//3
          print("NUMBER OF STEPS********** \(numberOfSteps)")
          for i in 0 ..< numberOfSteps { //4
              if i%4 == 0 {
                  sequencer.tracks[0].add(noteNumber: 69, velocity: 127, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 0.5))
              } else {
                  sequencer.tracks[0].add(noteNumber: 57, velocity: 127, position: AKDuration(beats: Double(i)), duration: AKDuration(beats: 0.5))
              }
          }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.MabSlider.setKnobImage(image: NSImage(named: "knob")!)
        self.MabSlider.setBarFillImage(image: NSImage(named: "fill")!)
        self.MabSlider.setBarFillBeforeKnobImage(image: NSImage(named: "beforeknob")!)
        self.MabSlider.setBarLeftAgeImage(image: NSImage(named: "leftage")!)
        self.MabSlider.setBarRightAgeImage(image: NSImage(named: "rightage")!)
        
        view.window?.styleMask.remove(.resizable)
        view.window?.styleMask.remove(.miniaturizable)
        view.window?.center()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.hexColor(rgbValue: 0x02394A).cgColor
        var midiNode = self.setupSynth();
        self.setupSequencer(midiNode: midiNode);
    }
    
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}


public extension NSColor {
  public class func hexColor(rgbValue: Int, alpha: CGFloat = 1.0) -> NSColor {

    return NSColor(red: ((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0, green:((CGFloat)((rgbValue & 0xFF00) >> 8))/255.0, blue:((CGFloat)(rgbValue & 0xFF))/255.0, alpha:alpha)

  }

}
