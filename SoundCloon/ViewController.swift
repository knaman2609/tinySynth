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

class ViewController: NSViewController {
    @IBOutlet var WaveView: NSStackView!
    @IBOutlet var ADSRGraphView: NSStackView!
    @IBOutlet var Bpmlabel: NSTextField!
    @IBOutlet var oscLabel: NSTextField!
    
    @IBOutlet var Filter: NSSlider!
    
    var fmWithADSR:AKMorphingOscillatorBank = AKMorphingOscillatorBank(waveformArray: [AKTable(.sine),
    AKTable(.triangle),
    AKTable(.sawtooth),
    AKTable(.square)]);
    
    var adsrView:AKADSRView = AKADSRView { att, dec, sus, rel in
       
    }
    
    var filter:AKBandPassButterworthFilter = AKBandPassButterworthFilter();
    var delay:AKDelay = AKDelay();
    var reverb:AKReverb = AKReverb();
    
    var scaleSelected:String = "Am";
    var currChordNotes:Array<Int> = [];
    var currChordName:String = "";
    var chordNotes: Dictionary<String, Array <Int>> = [
        "Am": [69, 72, 76],
        "G": [67, 71, 74],
        "C": [60, 64, 67],
    ]
    var chordProgressionBank : Dictionary<String, Array<String>> = [
        "Am": ["Am", "C"],
        "C": ["C", "G"]
    ]
    
    var plot: AKOutputWaveformPlot = AKOutputWaveformPlot();
    
    var timers:Array<Timer> = []
    var BpmValue:Int = 20;

    var syntStatus:String = "STOP";
    
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
        self.plot.resume()
        self.playChordProgression()
    }
       
    @IBAction func CSelected(_ sender: NSButton) {
        self.scaleSelected = "C";
        self.plot.resume();
        self.playChordProgression()
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
        self.BpmValue = sender.integerValue;
        
        self.Bpmlabel.stringValue = String(self.BpmValue);
        
        self.syntStatus = "STOP"
        self.playChordProgression();        
    }

       
    @IBAction func FilterChanged(_ sender: NSSlider) {
        var centerFrequency = sender.doubleValue*10.00;
        
        self.filter.centerFrequency = centerFrequency;
        
        print (centerFrequency)
    }
    
    @IBAction func stopSynth(_ sender: Any) {
        self.stopPreviousChords();
        
        for timer in self.timers {
            timer.invalidate();
        }
        
        self.syntStatus = "STOP";
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
     
        view.window?.styleMask.remove(.resizable)
        view.window?.styleMask.remove(.miniaturizable)
        view.window?.center()
                
        let amplitudeTracker = AKAmplitudeTracker(fmWithADSR)
        let booster = AKBooster(amplitudeTracker, gain: 5)
        
        self.delay = AKDelay(booster)
        self.reverb = AKReverb(self.delay)
        
        

        self.filter = AKBandPassButterworthFilter(self.reverb)
        filter.centerFrequency = 5_000;
        filter.bandwidth = 600 // Cents
        filter.rampDuration = 1.0
        
        AudioKit.output = self.filter;
        
        self.delay.time = 0.5;
        self.delay.feedback = 0.5 ;
        self.delay.dryWetMix = 0.5 ;
        
        self.reverb.loadFactoryPreset(.cathedral)
        self.reverb.dryWetMix = 0.5
        
        
        
        let frame = CGRect(x: 0.0, y: 0.0, width: 440, height: 330)
        self.plot = AKOutputWaveformPlot(frame: frame)

        plot.plotType = .rolling
        plot.backgroundColor = AKColor.clear
        plot.shouldCenterYAxis = true
            

        self.WaveView.addArrangedSubview(self.plot);
        
       
        
        do {
            try AudioKit.start()
            amplitudeTracker.start()
        } catch {
            
        }
        
        
        plot.resume()
        
        self.Bpmlabel.stringValue = String(self.BpmValue);
    }
    
    func createView(view: NSStackView, color: CGColor) {
        let myView = NSView();
        myView.wantsLayer  = true;
        myView.layer?.backgroundColor = color;
        
        
       view.addArrangedSubview(myView);
        
        let constraints = [
            myView.topAnchor.constraint(equalTo: view.topAnchor),
            myView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: myView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: myView.rightAnchor, constant: 0)
        ]

        NSLayoutConstraint.activate(constraints)
            
    }
    
    func stopPreviousChords() {
        for note in self.currChordNotes {
            self.fmWithADSR.stop(noteNumber: MIDINoteNumber(note))
        }
    }
    
    func playChord(chord : String) {
        self.stopPreviousChords();
        self.currChordName = chord;
        self.currChordNotes = self.chordNotes[chord]!;
    
        
        for note in self.currChordNotes {
            self.fmWithADSR.play(noteNumber: MIDINoteNumber(note), velocity: 40)
        }
       
//        print("playing");
//        print(chord);
    }
    
    
    func inverseChords() {
        var chordProgression  = self.chordProgressionBank[self.scaleSelected]!;
        
        if (self.currChordName == chordProgression[0]) {
            self.playChord(chord: chordProgression[1])
        } else {
            self.playChord(chord: chordProgression[0])
        }
      
    }
    
    func playChordProgression() {
        var index:Int = 0;
        
        if (self.syntStatus == "STOP") {
            self.syntStatus = "START"
        } else {
            return;
        }
        
        for timer in self.timers {
            timer.invalidate();
        }
        
        
        var timerID =
            Timer.scheduledTimer(withTimeInterval: TimeInterval(Float(60.0/self.BpmValue)), repeats: true) { timer in
                
                
                    self.inverseChords();
                
                index  = index + 1;
            }
        
        self.timers.append(timerID);
    }
    
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
}

