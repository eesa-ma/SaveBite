# Sample Restaurant Data for Firestore

## Collection: `restaurants`

To add restaurants to your Firestore database, go to Firebase Console > Firestore Database > Start Collection and create a collection named `restaurants`.

Then add documents with the following structure:

### Document 1
```json
{
  "name": "The Gourmet Burger",
  "cuisine": "American",
  "rating": 4.8,
  "reviews": 342,
  "distance": "0.5 km",
  "imageUrl": "https://via.placeholder.com/300x200?text=Burger+Restaurant",
  "isOpen": true,
  "deliveryTime": "20-30 min"
}
```

### Document 2
```json
{
  "name": "Pizza Palace",
  "cuisine": "Italian",
  "rating": 4.6,
  "reviews": 521,
  "distance": "1.2 km",
  "imageUrl": "https://via.placeholder.com/300x200?text=Pizza+Restaurant",
  "isOpen": true,
  "deliveryTime": "25-35 min"
}
```

### Document 3
```json
{
  "name": "Spice Garden",
  "cuisine": "Indian",
  "rating": 4.7,
  "reviews": 289,
  "distance": "2.1 km",
  "imageUrl": "https://via.placeholder.com/300x200?text=Indian+Restaurant",
  "isOpen": true,
  "deliveryTime": "30-40 min"
}
```

### Document 4
```json
{
  "name": "Sushi Paradise",
  "cuisine": "Japanese",
  "rating": 4.9,
  "reviews": 456,
  "distance": "1.8 km",
  "imageUrl": "https://via.placeholder.com/300x200?text=Sushi+Restaurant",
  "isOpen": true,
  "deliveryTime": "35-45 min"
}
```

### Document 5
```json
{
  "name": "Taco Fiesta",
  "cuisine": "Mexican",
  "rating": 4.5,
  "reviews": 198,
  "distance": "0.8 km",
  "imageUrl": "https://via.placeholder.com/300x200?text=Taco+Restaurant",
  "isOpen": true,
  "deliveryTime": "15-25 min"
}
```

### Document 6
```json
{
  "name": "Wok Express",
  "cuisine": "Chinese",
  "rating": 4.4,
  "reviews": 267,
  "distance": "1.5 km",
  "imageUrl": "https://via.placeholder.com/300x200?text=Chinese+Restaurant",
  "isOpen": false,
  "deliveryTime": "40-50 min"
}
```

## Field Types in Firestore

When adding these documents in Firebase Console, use these field types:
- `name`: string
- `cuisine`: string
- `rating`: number (double)
- `reviews`: number (integer)
- `distance`: string
- `imageUrl`: string
- `isOpen`: boolean
- `deliveryTime`: string

## Steps to Add Data:

1. Go to Firebase Console (https://console.firebase.google.com)
2. Select your project
3. Click on "Firestore Database" in the left menu
4. Click "Start collection"
5. Collection ID: `restaurants`
6. Add each document with auto-generated ID or custom IDs
7. For each document, add the fields listed above with their respective values

The app will automatically fetch and display these restaurants in the user dashboard!
