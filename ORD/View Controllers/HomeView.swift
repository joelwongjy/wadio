//
//  ContentView.swift
//  Wadio
//
//  Created by Joel Wong on 3/12/20.
//

import SwiftUI

enum ActiveSheet {
    case first, second
}

struct HomeView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var userSettings = UserSettings()
    
    @State var expand = false
    @State var offset : CGFloat = 0
    @State private var percentage = 0.5
    @State private var hideDetails = false
    @State private var activeSheet: ActiveSheet = .first
    @State private var showSheet = false
    @State private var titles: [String] = ["Working Days", "Completed", "Leave", "Off"]
    @State private var colors: [Color] = [.red, .orange, .blue, .green, .green]
    @State private var data: [Int] = [273,132,8,4]
    @State private var images: [String] = ["calendar.circle.fill", "checkmark.circle.fill", "bolt.circle.fill", "heart.circle.fill"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                VStack{
                    if !hideDetails {
                        HStack{
                            Button(action: {
                                self.showSheet = true
                                self.activeSheet = .first
                            }, label: {
                                Image(systemName: "gearshape").resizable().frame(width:25, height: 25).foregroundColor(.red)
                            })
                            
                            Spacer()
                            
                            Button(action: {
                                self.showSheet = true
                                self.activeSheet = .second
                            }, label: {
                                Image(systemName: "plus").resizable().frame(width:25, height: 25).foregroundColor(.red)
                            })
                        }.padding(.top)
                        .padding(.horizontal)
                    }
                    
                    ZStack {
                        PercentageRing(
                            ringWidth: 30, percent: percentage,
                            backgroundColor: Color.red.opacity(0.2),
                            foregroundColors: [.pink, .red]
                        )
                        .onAppear{
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                return withAnimation(Animation.spring(response: 0.8, dampingFraction: 1.0, blendDuration: 1.0)) {
                                    self.percentage = 70
                                }
                            }
                        }
                        .frame(width: 280, height: 280).padding(.top)
                        
                        VStack(spacing: -10) {
                            Text("298").font(.system(size: 60)).bold()
                            Text("days to ORD")
                                .font(.system(size: 30))
                        }
                    }.onTapGesture {
                        withAnimation{
                            self.hideDetails.toggle()
                        }
                    }
                    
                    if !hideDetails {
                        Collection<Grid, Int, Color, String>(titles: $titles, data: $data, colors: $colors, images: $images , cols: 2, spacing: 20) { title, data, color, image in
                            Grid(title: title, days: data, color: color, image: Image(systemName: image))
                        }.padding(20)
                        .animation(.easeInOut)
                        
                        Spacer()
                    }
                }
                
//                GeometryReader{ reader in
//                    VStack{
//                        BottomSheet(offset: $offset, value: (-reader.frame(in: .global).height + 150))
//                            .offset(y: reader.frame(in: .global).height - 140)
//                            // adding gesture....
//                            .offset(y: offset)
//                            .gesture(DragGesture().onChanged({ (value) in
//                                    // checking the direction of scroll....
//
//                                    // scrolling upWards....
//                                    // using startLocation bcz translation will change when we drag up and down....
//                                    if value.startLocation.y > reader.frame(in: .global).midX{
//                                        if value.translation.height < 0 && offset > (-reader.frame(in: .global).height + 150){
//                                            offset = value.translation.height
//                                        }
//                                    }
//                                    if value.startLocation.y < reader.frame(in: .global).midX{
//                                        if value.translation.height > 0 && offset < 0{
//                                            offset = (-reader.frame(in: .global).height + 150) + value.translation.height
//                                        }
//                                }
//
//                            }).onEnded({ (value) in
//                                withAnimation{
//                                    // checking and pulling up the screen...
//                                    if value.startLocation.y > reader.frame(in: .global).midX{
//                                        if -value.translation.height > reader.frame(in: .global).midX{
//                                            offset = (-reader.frame(in: .global).height + 150)
//                                            return
//                                        }
//                                        offset = 0
//                                    }
//                                    if value.startLocation.y < reader.frame(in: .global).midX{
//                                        if value.translation.height < reader.frame(in: .global).midX{
//                                            offset = (-reader.frame(in: .global).height + 150)
//                                            return
//                                        }
//                                        offset = 0
//                                    }
//                                }
//                            }))
//                    }
//                }.edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSheet) {
                if self.activeSheet == .first {
                    SettingsView(showSheet: $showSheet)
                }
                else {
                    AddEvent { title, type, halfday, startDate, endDate in
                        self.addEvent(title: title, type: type, halfday: halfday, startDate: startDate, endDate: endDate)
                        self.showSheet = false
                    }
                }
            }
        }
    }
    
    func addEvent(title: String, type: String, halfday: Bool, startDate: Date, endDate: Date) {
        let newEvent = Event(context: managedObjectContext)
        
        newEvent.title = title
        newEvent.type = type
        newEvent.halfday = halfday
        newEvent.title = title
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        
        saveContext()
    }
    
    func saveContext() {
        do {
            try managedObjectContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
