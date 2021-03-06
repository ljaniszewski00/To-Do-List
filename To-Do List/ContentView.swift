//
//  ContentView.swift
//  To-Do List
//
//  Created by Łukasz Janiszewski on 17/07/2021.
//

import SwiftUI
import CoreData

let dateRange: ClosedRange<Date> = {
    let calendar = Calendar.current
    let startComponents = DateComponents(year: 2021, month: 1, day: 1)
    let endComponents = DateComponents(year: 2021, month: 12, day: 31, hour: 23, minute: 59, second: 59)
    return calendar.date(from:startComponents)!
        ...
        calendar.date(from:endComponents)!
}()

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.locale) private var locale
    @AppStorage("isDarkMode") private var darkMode = false
    @State var showAddFormView = false
    @State var showDetailView = false
    @State var activeItem = Item()

    @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Item.date, ascending: true)],
            animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            if showAddFormView {
                AddTaskView()
            } else if showDetailView {
                DetailView(newItem: activeItem)
            } else {
                VStack {
                    TopView()
                        .frame(width: screenWidth, height: screenHeight * 0.14)
                        .padding(.top, screenHeight * 0.025)
                    
                    List {
                        ForEach(items) { item in
                            HStack {
                                VStack {
                                    Group {
                                        Text(LocalizedStringKey(item.day!))
                                            .font(.system(size: screenHeight * 0.018))
                                        Text(getStringFromDate(date: item.date!))
                                            .font(.system(size: screenHeight * 0.02))
                                    }
                                    .foregroundColor(.gray)
                                    
                                }
                                .frame(width: screenWidth * 0.22, height: screenHeight * 0.2)
                                
                                Divider()
                                
                                Text("\(item.title!)")
                                    .font(.system(size: screenWidth * 0.05))
                                    .frame(width: screenWidth * 0.5, height: screenHeight * 0.04, alignment: .leading)
                                
                                if item.finished == true {
                                    ZStack {
                                        Circle().foregroundColor(.green)
                                            .frame(width: screenWidth * 0.2, height: screenHeight * 0.035)
                                            .onTapGesture {
                                                item.finished = false
                                                saveContext()
                                            }
                                        Text("✓")
                                    }
                                } else {
                                    Circle().foregroundColor(.red)
                                        .frame(width: screenWidth * 0.2, height: screenHeight * 0.035)
                                        .onTapGesture {
                                            item.finished = true
                                            saveContext()
                                        }
                                }
                            }
                            .frame(width: screenWidth * 0.9, height: screenHeight * 0.06)
                            .onTapGesture {
                                activeItem = item
                                withAnimation(.spring()) {
                                    showDetailView.toggle()
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(Color.blue)
                            .frame(width: screenWidth * 0.4, height: screenHeight * 0.065)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showAddFormView = true
                            }
                        }) {
                            Label("Add Task", systemImage: "plus")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, screenHeight * 0.026)
                    
                }
                .ignoresSafeArea(.keyboard)
                .preferredColorScheme(darkMode ? .dark : .light)
                .environment(\.colorScheme, darkMode ? .dark : .light)
            }
        }
    }
    
    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let items: [Item]?
    }
    
    private func getStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/YY"
        return dateFormatter.string(from: date)
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            saveContext()
        }
    }
}

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isDarkMode") private var darkMode = false
    @State var showTaskView = false
    @State private var itemTitle = ""
    @State private var itemFullDescription = ""
    @State private var itemDay = ""
    @State private var itemDate = Date()
    @State private var itemFinished = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            VStack {
                if showTaskView {
                    ContentView()
                } else {
                    TopView()
                        .frame(width: screenWidth, height: screenHeight * 0.14)
                        .padding(.top, screenHeight * 0.025)
                    
                    Spacer()
                    
                    VStack {
                        Spacer()
                        
                        Section(header: Text("TITLE")) {
                            TextField("", text: $itemTitle)
                                .padding(.horizontal, screenWidth * 0.05)
                        }
                        
                        Spacer()
                        
                        Section(header: Text("DESCRIPTION")) {
                            TextField("", text: $itemFullDescription)
                                .padding(.horizontal, screenWidth * 0.05)
                        }
                        
                        Spacer()
                        
                        Section(header: Text("DATE")) {
                            DatePicker("", selection: $itemDate, in: dateRange, displayedComponents: [.date])
                                .padding(.trailing, screenWidth * 0.37)
                        }
                        
                        Spacer()
                        
                        Section(header: Text("FINISHED")) {
                            Toggle("", isOn: $itemFinished)
                                .padding(.trailing, screenWidth * 0.45)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack (spacing: screenWidth * 0.24) {
                        Button(action: { showTaskView = true }) {
                            Label("Cancel", systemImage: "")
                                .foregroundColor(.white)
                                .padding(.trailing, screenWidth * 0.02)
                        }
                        .background(RoundedRectangle(cornerRadius: 25, style: .continuous)
                                        .fill(Color.red)
                                        .frame(width: screenWidth * 0.4, height: screenHeight * 0.065))
                        
                        Button(action: {
                            let item = Item(context: viewContext)
                            
                            item.title = itemTitle
                            item.fullDescription = itemFullDescription
                            item.day = getDayOfTheWeekFromDate(passedDate: itemDate)
                            item.date = itemDate
                            item.finished = itemFinished
                            saveContext()
                            withAnimation {
                                showTaskView.toggle()
                            }
                        }) {
                            Label("Save Task", systemImage: "")
                                .foregroundColor(.white)
                        }
                        .background(RoundedRectangle(cornerRadius: 25, style: .continuous)
                                        .fill(Color.green)
                                        .frame(width: screenWidth * 0.4, height: screenHeight * 0.065))
                    }
                    .padding(.bottom, screenHeight * 0.05)
                    .padding(.top, screenHeight * 0.15)
                }
            }
            .ignoresSafeArea(.keyboard)
            .preferredColorScheme(darkMode ? .dark : .light)
            .environment(\.colorScheme, darkMode ? .dark : .light)
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct DetailView: View {
    @AppStorage("isDarkMode") private var darkMode = false
    @State var showTaskView = false
    @State private var item: Item
    
    init(newItem: Item) {
        _item = State(initialValue: newItem)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            VStack {
                if showTaskView {
                    ContentView()
                } else {
                    TopView()
                        .frame(width: screenWidth, height: screenHeight * 0.14)
                        .padding(.top, screenHeight * 0.025)
                    
                    Spacer()
                    
                    VStack {
                        Spacer()
                        
                        Section(header: Text("TITLE")) {
                            TextField(self.item.title!, text: $item.title ?? "")
                                .padding(.horizontal, screenWidth * 0.05)
                        }
                        
                        Spacer()
                        
                        Section(header: Text("DESCRIPTION")) {
                            TextField(self.item.fullDescription!, text: $item.fullDescription ?? "")
                                .padding(.horizontal, screenWidth * 0.05)
                        }
                        
                        Spacer()
                        
                        Section(header: Text("DATE")) {
                            DatePicker("", selection: $item.date ?? Date(), in: dateRange, displayedComponents: [.date])
                                .padding(.trailing, screenWidth * 0.37)
                        }
                        
                        Spacer()
                        
                        Section(header: Text("FINISHED")) {
                            Toggle("", isOn: $item.finished)
                                .padding(.trailing, screenWidth * 0.45)
                        }
                    }
                    Button(action: {
                        withAnimation {
                            showTaskView.toggle()
                        }
                    }) {
                        Label("Save Changes", systemImage: "")
                            .foregroundColor(.white)
                    }
                    .background(RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(Color.green)
                                    .frame(width: screenWidth * 0.38, height: screenHeight * 0.065, alignment: .center))
                    .padding(.bottom, screenHeight * 0.05)
                    .padding(.top, screenHeight * 0.15)
                }
            }
            .ignoresSafeArea(.keyboard)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .preferredColorScheme(darkMode ? .dark : .light)
            .environment(\.colorScheme, darkMode ? .dark : .light)
        }
    }
    
}

struct TopView: View {
    @AppStorage("isDarkMode") private var darkMode = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundColor(darkMode == true ? .white : .black)
                        .frame(width: screenWidth * 0.55, height: screenHeight * 0.75)
                    
                    Text("To-Do List 📝")
                        .font(.largeTitle)
                        .foregroundColor(darkMode == true ? .black : .white)
                }
                .padding(.leading, screenWidth * 0.05)
                
                Spacer()
                
                VStack {
                    Text("☀️ / 🌙")
                        .padding(.trailing, screenWidth * 0.065)
                    Toggle("", isOn: $darkMode)
                        .toggleStyle(SwitchToggleStyle(tint: .clear))
                        .frame(width: screenWidth * 0.15)
                        .padding(.trailing, screenWidth * 0.1)
                }
                .padding(.bottom, screenHeight * 0.23)
            }
        }
    }
}

public func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

public func getDayOfTheWeekFromDate(passedDate: Date) -> String {
    let date = passedDate
    let calendar = Calendar.current
    let components = calendar.dateComponents([.weekday], from: date)
    let numberOfDayOfWeek = components.weekday
    var dayOfWeek: String
    
    switch numberOfDayOfWeek {
    case 1:
        dayOfWeek = "Sunday"
    case 2:
        dayOfWeek = "Monday"
    case 3:
        dayOfWeek = "Tuesday"
    case 4:
        dayOfWeek = "Wednesday"
    case 5:
        dayOfWeek = "Thursday"
    case 6:
        dayOfWeek = "Friday"
    case 7:
        dayOfWeek = "Saturday"
    default:
        dayOfWeek = ""
    }
    
    return dayOfWeek
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


