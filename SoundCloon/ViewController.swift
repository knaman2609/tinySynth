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
    let sequencer = AKAppleSequencer()//2
    let sequenceLength = AKDuration(beats: 8.0)
    
    @IBOutlet var WaveView: NSStackView!
    @IBOutlet var ADSRGraphView: NSStackView!
    @IBOutlet var oscLabel: NSTextField!
    
    @IBOutlet var Filter: NSSlider!
    
    var fmWithADSR:AKMorphingOscillatorBank = AKMorphingOscillatorBank(waveformArray: [
        AKTable(.sine),
        AKTable(.sawtooth),
        AKTable(.triangle),
        AKTable(.square)]);

    
    var filter:AKBandPassButterworthFilter = AKBandPassButterworthFilter();
    var delay:AKDelay = AKDelay();
    var reverb:AKReverb = AKReverb();
    var plot: AKOutputWaveformPlot = AKOutputWaveformPlot();
    var amplitudeTracker:AKAmplitudeTracker = AKAmplitudeTracker();
    
    
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
//        self.plot.resume()
    }
    
    @IBAction func CSelected(_ sender: NSButton) {
        self.scaleSelected = "C";
//        self.plot.resume();
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
        self.sequencer.setTempo(sender.doubleValue);
    }
    
    
    @IBAction func FilterChanged(_ sender: NSSlider) {
        var centerFrequency = sender.doubleValue*10.00;
        
        self.filter.centerFrequency = centerFrequency;
        
        print (centerFrequency)
    }
    
    @IBAction func stopSynth(_ sender: Any) {
        self.stopPreviousChords();
        
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

        plot.resume()
    }
    
    func setupSynth() -> AKMIDINode{
        let midiNode = AKMIDINode(node: self.fmWithADSR)
        
        self.amplitudeTracker = AKAmplitudeTracker(midiNode)
        let booster = AKBooster(self.amplitudeTracker, gain: 5)
        
        self.delay = AKDelay(booster)
        self.delay.time = 0.5;
        self.delay.feedback = 0.5 ;
        self.delay.dryWetMix = 0.5 ;
        
        self.reverb = AKReverb(self.delay)
        self.reverb.loadFactoryPreset(.cathedral)
        self.reverb.dryWetMix = 0.5
        
        self.filter = AKBandPassButterworthFilter(self.reverb)
        self.filter.centerFrequency = 5_00;
        self.filter.bandwidth = 600 // Cents
        self.filter.rampDuration = 1.0
    
        
        
        self.setupPlot();
        
        return midiNode;
    }
    
    func setupSequencer(midiNode: AKMIDINode) {
        let track = sequencer.newTrack()//2
        sequencer.setLength(sequenceLength)//3
        self.generateSequence() //4
        AudioKit.output = self.filter;
           
        do {
            try? AudioKit.start()//6
            self.amplitudeTracker.start();
        } catch{
               
        }
           
        track?.setMIDIOutput(midiNode.midiIn);
        sequencer.setTempo(20.0)//8
        sequencer.enableLooping()//9
        sequencer.play()//10
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
        
        view.window?.styleMask.remove(.resizable)
        view.window?.styleMask.remove(.miniaturizable)
        view.window?.center()
        
        
        var midiNode = self.setupSynth();
        self.setupSequencer(midiNode: midiNode);
        
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
            self.fmWithADSR.play(noteNumber: MIDINoteNumber(note), velocity: 20)
        }
    }
    
    
    func inverseChords() {
        var chordProgression  = self.chordProgressionBank[self.scaleSelected]!;
        
        if (self.currChordName == chordProgression[0]) {
            self.playChord(chord: chordProgression[1])
        } else {
            self.playChord(chord: chordProgression[0])
        }
        
    }
    
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}

