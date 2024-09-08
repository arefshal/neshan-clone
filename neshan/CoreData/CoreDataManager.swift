//
//  CoreDataManager.swift
//  neshan
//
//  Created by Aref on 9/8/24.
//

import CoreData

/// Manages Core Data operations for saved 
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SavedLocations")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func fetchSavedLocations() -> [SavedLocation] {
        let request: NSFetchRequest<SavedLocation> = SavedLocation.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching saved locations: \(error)")
            return []
        }
    }
    
    func saveLocation(_ searchResult: SearchResult) {
        let savedLocation = SavedLocation(context: context)
        savedLocation.title = searchResult.title
        savedLocation.latitude = searchResult.location.y
        savedLocation.longitude = searchResult.location.x
        saveContext()
    }
    
    func deleteLocation(_ savedLocation: SavedLocation) {
        context.delete(savedLocation)
        saveContext()
    }
    
    
    func saveLocationsToUserDefaults() {
        let savedLocations = fetchSavedLocations()
        let codableLocations = savedLocations.map { SavedLocationCodable(from: $0) }
        
        if let encodedData = try? JSONEncoder().encode(codableLocations) {
            UserDefaults.standard.set(encodedData, forKey: "SavedLocations")
        }
    }
    
    
    func loadLocationsFromUserDefaults() -> [SavedLocationCodable] {
        if let savedData = UserDefaults.standard.data(forKey: "SavedLocations"),
           let decodedLocations = try? JSONDecoder().decode([SavedLocationCodable].self, from: savedData) {
            return decodedLocations
        }
        return []
    }
}
