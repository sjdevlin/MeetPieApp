//
//  MonitorView2.swift
//  Profiles
//
//  Created by Stephen Devlin on 18/09/2022.
//

import SwiftUI

struct MonitorView: View {
    
    @StateObject var mic = MicrophoneMonitor()
    @State private var showingAlert = false
    @State private var meetingEnded = false
    
    let limits:MeetingLimits
    
    
    var body: some View
    {
            ZStack
            {
                NavigationLink(destination: SummaryView(meeting: mic.meeting, limits: limits), isActive: $meetingEnded,
                               label: { EmptyView() }
                ).navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                
                VStack
                {
                    TabView
                    {
                        TimeView(meeting:$mic.meeting,meetingDuration:limits.meetingDurationMins)
                        ShareView(meeting:$mic.meeting,maxShare:limits.maxShareVoice)
                        TurnView(meeting:$mic.meeting,maxTurnLength:limits.maxTurnLengthSecs)
                    }
                    
                    Button("Pause") {
                        mic.pauseMonitoring()
                        showingAlert = true
                    }.alert(isPresented:$showingAlert)
                    {
                        Alert(title: Text("Meeting Paused"),
                              primaryButton: .destructive(Text("End")) {
                            mic.stopMonitoring()
                            meetingEnded = true
                        },
                              secondaryButton: .destructive(Text("Resume")) {
                            mic.startResumeMonitoring(mode:"Resume")
                            print("Resume")
                        }
                        )
                    }.foregroundColor(Color.white)
                        .frame(minWidth: 200, minHeight: 60)
                        .background(RoundedRectangle(cornerRadius: 12   ).fill(Color.orange).opacity(0.5))
                        .font(.system(size: 20))
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                
                Spacer()
                
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
                
            .tabViewStyle(.page)
            .onAppear(
                perform: {
                    mic.startResumeMonitoring(mode:"Start")
                }
            )
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
    }

    }
    
    
    
    struct TimeView: View {
        @Binding var meeting: MeetingData
        let meetingDuration:Int
        
        
        var body: some View {
            
            let minutesRemaining:Int = meetingDuration >= meeting.elapsedTimeMins ? meetingDuration - meeting.elapsedTimeMins : 0
            let percentageRemaining:CGFloat = CGFloat(minutesRemaining) / CGFloat(meetingDuration)
            let percentageGone:CGFloat = 1 - percentageRemaining
            let rectangleRemaining:CGFloat = (kRectangleHeight * percentageRemaining)
            let rectangleGone:CGFloat = (kRectangleHeight * percentageGone)
            
            VStack(spacing:0){
                HStack {
                    Spacer()
                    Text ("Minutes\nRemaining")
                        .font(.system(size: 32))
                        .multilineTextAlignment(.center)
                    Spacer()
                }.padding(.top, 20)
                
                
                Spacer()
                ZStack{


                    VStack(spacing:0){
                        
                        Rectangle()
                            .fill(Color(.systemGray3))
                            .frame(width: kRectangleWidth, height:rectangleGone)
                        
                        Rectangle()
                            .fill((percentageGone <= kAmber) ? Color(.lightGray) : Color.orange)
                            .frame(width: kRectangleWidth, height: rectangleRemaining)
                    }
                    
                    .mask(RoundedRectangle(cornerRadius:38)
                        .frame(width: kRectangleWidth, height: kRectangleHeight))
                    
                    Text(String(minutesRemaining))
                        .font(.system(size: 65))
                        .foregroundColor((percentageGone <= kAmber) ? Color.white :Color.orange)

                }
                
                Spacer()
            }.navigationBarBackButtonHidden(true)
            
        }
    }
    
    struct ShareView: View {
        
        @Binding var meeting: MeetingData
        let maxShare: Int
        
        var body: some View {
            
            let percentageCoach:CGFloat = CGFloat(meeting.participant[kCoach].voiceShare)
            let percentageClient:CGFloat = CGFloat(meeting.participant[kClient].voiceShare)
            let maxShareFloat = CGFloat(maxShare) / 100.0
            let rectangleCoach:CGFloat = kRectangleHeight * percentageCoach * 0.85
            let rectangleClient:CGFloat = kRectangleHeight * percentageClient * 0.85
            let rectangleLimit:CGFloat = kRectangleHeight * maxShareFloat * 0.85
            let limitLine:CGFloat = 90 + kRectangleHeight - rectangleLimit
            
            
            ZStack
            {
                    ZStack
                    {

                        VStack{
                            Spacer()
                            Spacer()

                            Text(String(format:"%.0f",meeting.participant[kClient].voiceShare*100)+"%")
                                .font(.system(size: 48))
                                .frame(width:kRectangleWidth, height:rectangleClient)
                                .padding(.bottom)
                                .foregroundColor(.white)
                                .background(percentageCoach > maxShareFloat * kAmber ?  Color(.lightGray) : Color.green)

                            Text(String(format:"%.0f",meeting.participant[kCoach].voiceShare*100)+"%")
                                .font(.system(size: 65))
                                .frame(width:kRectangleWidth, height:rectangleCoach)
                                .padding(.bottom)
                                .foregroundColor(.white)
                                .background(percentageCoach > maxShareFloat * kAmber ? Color.orange: Color(.lightGray))
                            Spacer()

                        }
                        
                        Text(String(maxShare)+"%")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .position(x: 50, y: limitLine)

                        Path() {path in
                            path.move(to: CGPoint(x:75,y: limitLine))
                            path.addLine(to: CGPoint(x:300, y: limitLine))
                        }.stroke(.white, lineWidth: 4)
                    }
                
                VStack {
                    HStack {
                        Spacer()
                        Text ("Voice\nShare")
                            .font(.system(size: 32))
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }.padding(.top, 20)
                    Spacer()
                }
                
            }
            
        }
        
    }
    
    struct TurnView: View
    {
        @Binding var meeting: MeetingData
        let maxTurnLength:Int
        
        let radius: CGFloat = 120
        let pi = Double.pi
        let dotLength: CGFloat = 4
        let spaceLength: CGFloat = 10.8
        let dotCount = 60
        let circumference: CGFloat = 754.1

        let clientRadius: CGFloat = 75
        let clientDotLength: CGFloat = 3
        let clientSpaceLength: CGFloat = 8
        let clientCircumference: CGFloat = 471.3

        
        var body: some View {
            
            let arcFractionLimit = CGFloat(maxTurnLength)/60
            let arcFraction = CGFloat(meeting.participant[kCoach].currentTurnDuration)/60
            let clientArcFraction = CGFloat(meeting.participant[kClient].currentTurnDuration)/60
            let turnPercentage = CGFloat(meeting.participant[kCoach].currentTurnDuration) / CGFloat(maxTurnLength)
            ZStack{
                VStack{
                    ZStack{
                        Circle()
                            .trim(from: 0.0, to: clientArcFraction)
                            .rotation(.degrees(-90))
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 12, lineCap: .butt, lineJoin: .miter, miterLimit: 0, dash: [clientDotLength, clientSpaceLength], dashPhase: 0))
                            .frame(width: clientRadius * 2, height: clientRadius * 2)
                        
                        Text(String(meeting.participant[kClient].currentTurnDuration)+" s")
                            .font(.system(size: 48))
                            .foregroundColor(Color.green)
                    }.padding(.bottom, 40)
                        .padding(.top, 40)

                    ZStack{
                        Circle()
                            .trim(from: 0.0, to: arcFraction)
                            .rotation(.degrees(-90))
                            .stroke(
                                (turnPercentage < kAmber) ?  Color.white: Color.orange,
                                style: StrokeStyle(lineWidth: 12, lineCap: .butt, lineJoin: .miter, miterLimit: 0, dash: [dotLength, spaceLength], dashPhase: 0))
                            .frame(width: radius * 2, height: radius * 2)
                        
                        Circle()
                            .trim(from: 0.0, to: arcFractionLimit)
                            .rotation(.degrees(-90))
                            .stroke(Color.gray,style: StrokeStyle(lineWidth:8))
                            .frame(width:radius * 2.2, height:radius * 2.2)
                        
                        Text(String(meeting.participant[kCoach].currentTurnDuration)+" s")
                            .font(.system(size: 65))
                            .foregroundColor(
                                ((CGFloat(meeting.participant[kCoach].currentTurnDuration) / CGFloat(maxTurnLength)) < kAmber) ?  Color.white: Color.orange                    )
                    }
                }

                
                
                VStack {
                    HStack {
                        Spacer()
                        Text ("Turn\nLength")
                            .font(.system(size: 32))
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }.padding(.top, 20)
                    
                    Spacer()
                }
                
                
            }
        }
    }
    
    struct TurnView_Previews: PreviewProvider {
        static var previews: some View {
            
            TurnView(meeting:  .constant(MeetingData.example), maxTurnLength: 45)
                .preferredColorScheme(.dark)
            
        }
    }
    
    struct ShareView_Previews: PreviewProvider {
        static var previews: some View {
            
            ShareView(meeting:  .constant(MeetingData.example), maxShare: 50)
                .preferredColorScheme(.dark)
            
        }
    }
    
    struct TimeView_Previews: PreviewProvider {
        static var previews: some View {
            
            TimeView(meeting:  .constant(MeetingData.example), meetingDuration: 30)
                .preferredColorScheme(.dark)
            
        }
    }
    
    
    
    // this struct and view extension allows individually rounded corners
    
    
    
