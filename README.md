# ootd v1

Concept: iOS app that merges the spontaneity of BeReal, the inspiration of Pinterest, and the shopping functionality of LTK. 

User ability:
- Share their Outfit of the Day (OOTD) via a live photo.
- Tag and share links to the items they’re wearing.
- Discover and favorite others' outfits.
- Interact with their idols, friends, and the broader community.
- Browse trending outfits and profiles as a guest.

Functionalities:
  General:
    Guest Access:
      Guests can browse trending posts and public profiles but cannot interact (e.g. favorite, comment, or post).
    Post Watermark:
      Every post has the "ootd.png" watermark in the bottom-right corner.
    Live Photo Upload:
      Photos must be taken live in-app; uploads from the photo library are not allowed.
      
  User:
    Post OOTD:
      Live camera capture only.
      Option to tag outfit items with titles and shopping links.
      Automatically adds the watermark to images.
  Favorites:
    Users can "favorite" posts by tapping the star icon.
    Only the poster sees who has favorited their post. Others only see # of favorites on a post. 
    Favorited posts appear in the user’s Favorites Tab.
    Favorites function identical to VSCO favorites. 
  Comments:
    Users can comment on any permitted post.
    Users can limit comments on their posts to followers or friends only. 
    Post creators can delete any comments on their own posts.
    Comments have a max of 70 characters.
  Tagged Items:
    Posts can include tagged items (title + URL).
    Shopping bag icon opens a view displaying the items with clickable links.
  Private Profiles:
    Users can toggle privacy settings to restrict profile access.
    Users must request access to follow private profiles.
    Public profile view is restricted to only followers if the profile is private. 
  Notifications:
    New comments on your post
    Favorites on your post
    New followers or follow requests.
  Social Sharing:
    Users can share their posts externally (e.g., Instagram, Facebook, download image) with watermark.

    
Navigation:

LandingView:
  Logged-Out State:
    Displays TrendingView (scrolling view of trending OOTDs).
    Buttons for:
    Sign Up → Redirects to SignUpView.
    Log In → Redirects to LoginView.
  Logged-In State:
    Redirects to LoggedInView.

LoggedInView:
  # top middle of screen
  Logo:
    ootd.png
  # main portion of screen, below the 
  Following:
    Descending, chronological posts from TODAY ONLY from followed accounts.
    At bottom of posts, recommendationsView is displayed.
  Trending:
    DisplaysTrendingView
  # in top right
  User Profile (profile picture circle):
    Sends to UserProfileView
  # in top left
  Recommendations (friendship icon)
    Sends to RecommendationsView
    
  TrendingView:
    Displays all public OOTDs based on engagement. Decreasing from most favorites to least favorites.
    Each post includes:
      Picture with watermark.
      Profile picture and username.
      Favorites count, comment count, and shopping bag icon (if applicable).
    Guest users:
      Can view this page, and public profiles, but not interact.
      
  PostOOTDView:
    Accessed via a "+" button in the bottom navigation bar.
    Opens live camera capture (no photo library uploads)
      when photo is captured, it goes to a new page which allows you to write a caption, adjust comment settings, and add items prior to clicking "post ootd"
      Write a caption:
        max 120 characters
      Tag items with:
        Title: Item name (e.g., "Black Turtleneck").
        Link: URL for purchase.
      Automatically adds the watermark.
      Posts appear in the user’s profile and followers' feeds.
      
  UserProfileView:
    Displays user-specific content to the user.
    Sections:
      Profile (top middle):
        instead of OOTD.png in top middle, instead it's the username which is above
        profile picture which is above
        full name, which is next to clickable instagram handle if included, which is above 
        followers (#) button & following (#) button next to eachother
      Today's OOTD:
        Large post in the middle of the screen. Clickable to go to postView.
      Your OOTDs:
        Grid of all posts created in chronological order, 3 posts per row. if you click any post, it goes to the postView for those posts. 
    Home Button (home icon in top left)
      Navigates to LoggedInView
    Favorites Tab (star in top right)
      Grid of posts favorited by the user (visible only to the user)
    Settings Tab (settings icon in top right)
      adjust username, bio, and profile picture
      toggle between public/private profile button
      logout button.

    PublicProfileView:
      When a guest or other user clicks a profile, this is what they see.
      Sections:
        Profile (top middle):
          instead of OOTD.png in top middle, instead it's the @username which is above
          profile picture which is above
          full name, which is next to clickable instagram handle if included, which is above
          followedBy string (see below) which is above
          followers (#) button & following (#) button next to eachother
        Today's OOTD:
          Large post in the middle of the screen. Clickable to go to postView.
        {firstname}'s OOTDs:
          Grid of posts created by the user, each one Clickable to go to PostView.
      Home Button (home icon in top left)
        Navigates to LoggedInView
      followedBy string:
        if logged out:
          ignore and remove string from PublicProfileView.
        if logged in:
          check if viewer follows profiles which also follow this profile
            if no
              remove string from PublicProfileView.
            if yes
              check if the value of profiles which follow this account is greater than 2 profiles
                if yes
                  show the three profile pictures with the most followers
                if no
                  show all profile pictures which the viewer follows, which also follow this profile. 
          if the viewer clicks the followedBy string, it shows FollowerView


  FavoritesView:
    shows in a grid all posts a user has favorited
    Each post is clickable which will send to the PostView

  PostView:
    Displays post, favorites #, comments, and items button.
      PostView is extremely similar to instagram postview. 
      Shows photo as majority of screen, with options on bottom:
        Star (Favorite) (#):
          Clicking this as a user favorites the post.
          Clicking this as a guest navigates SignUpView
        Comment (comment) (#):
          Clicking this opens the comments as a popup which can be swiped out of
          Displays all comments in chronological order
          Comment strings have commenter profile picture, username, and content of the comment. 
          Text box on bottom to add a new comment
          If you click text box as a guest, navigate to SignUpView
          You can delete your own comments, or owner of post can delete on any of their comments by swiping them to the left, displaying a red "trash" icon, deleting the comment. 
        Bag (items) (#):
          if #=0, don't display bag. 
          Opens a popup similar to comments:
            A list of tagged items, each with a title and URL.
          In-App Browser:
            Clicking a link opens the page in an embedded browser.
        Share (SocialSharingView):
          Options to share posts externally:
            if share button is clicked by poster:
              Offers instagram sharing (ig logo):
                Takes the photo with watermark directly to instagram app to post on story (https://developers.facebook.com/docs/permissions#instagram_content_publish)
              Copy Link:
                Creates shareable link (copy icon):
                  if clicked, it needs to send to the the exact post on the ootd app.
                  if the app is not installed, it needs to send to ootd on the app store. 
                  # if clicked on android, i need to update the server to send any unknown extensions to the homepage
              else:
                copies post link and sends success message 
          Post Link:
            each post has a postid attached, so if you click url/postid on ios it will open directly to the postview
          
          
                  
  SignUpView / LogInView:
    Sign Up:
      How do you want to sign up?:
        Through GMAIL
        Phone Number
          Once Confirmed, design profile. Required Fields:
            Username
            ProfilePicture
            Bio
            Full Name
          If can't confirm, then screen displays that we couldn't log you in through GMAIL or phone number, sends back to LandingView
    Log In:
      How do you want to log in?:
        Through gmail
        Phone number
          If successful, navigate LoggedInView
          If unsuccessful, error message then return to LandingView.
          
  NotificationsView:
    Shows each activity relevant to the user:
      On click, sends to the PostView in reference.
      Notifications:
        New comments on your posts.
        Favorites on posts.
        New Followers:
          If public, shows as new follower
          If private, shows as follow request (with accept/decline options).

  ExploreView:
    Search for other users:
      Exact same functionality to VSCO's explore/search feature. 
    Search for items:
      Ex: "Nike Shirt" will rely on a built-in search engine to pull up posts with items titled "Nike shirt" or something similar.
    Only one search bar, where the page will look identical to vsco's

  RecommendationsView:
    Functions the exact same way as BeReal recommendations, lists profile by profile based on number of mutual friends.
    Lists profile by profile in order of mutual friends, and then at end lists profiles based on total followers. 
    
  
  Bottom Navigation Bar (persistent across views):
    Home: Navigate LandingView or LoggedInView
    Explore: Navigate ExploreView
    Post OOTD: Navigate PostOOTDView.
    Notifications: Navigate NotificationsView
    Profile: Navigate UserProfileView

    
Backend:
  Authentication & User Management:
    FireBaseAuth:
      Enable Gmail and phone number authentication.
      Create user profiles linked to Firebase UID.
      Implement unique username validation during sign-up.
      Store user metadata (username, bio, profile picture, full name, privacy settings).
      
  Database Structure
    FirebaseFireStore:
      Collections:
        Users: Store user metadata and followers/following lists.
        Posts: Store post data (image URL, timestamp, favorites count, comments, and tagged items).
        Notifications: Track activities like comments, favorites, and follow requests.
      Define security parameters:
        Restrict write access to authenticated users.
        Enforce privacy settings
        
  Storage
    File Storage:
      Folder structure:
        /users/{userId}/profilePicture.jpg
        /posts/{postId}/image.jpg
      
  Notifications
    Firebase Cloud Messaging:
      Enable push notifications for:
        Comments on user posts.
        Favorites on user posts.
        Follow requests and new followers.
      Design a notification listener for real-time updates in-app.
      
  Sharing & Deep Linking
    Firebase Dynamic Links:
      Create shareable links for posts (url/postId).
        Redirect to:
          The post in-app (if installed).
          The App Store (if the app is not installed).
          Handle expired posts (redirect to the user's PublicProfileView).
          
  Search Functionality
    Firestore Indexing:
      Enable search by username and tagged items (e.g., “Nike Shirt”).
      Add real-time updates to indexes for new posts and profiles.
      
Recommendations
  Build Recommendations Algorithm:
    Rank profiles by:
      1) Number of mutual friends.
      2) Total followers.
  Store recommendations as a cached list in Firestore for efficiency.
  
Explore & Trending
  Create Queries for ExploreView:
    Fetch profiles by search criteria.
  Use Firestore queries to fetch trending posts based on:
    Total favorites.
    Engagement within the last 24 hours.
    
Security Rules
  Define Firestore Rules:
    Restrict:
      Viewing private profiles to approved followers.
      Commenting and favoriting to logged-in users.
      Editing or deleting posts/comments to their owners.
      
Analytics
  Set up Firebase Analytics:
    Track:
      Post engagement (favorites, comments).
      User activity (daily active users, retention).
      Most searched items and users.

In-App Browser
  Use Safari View Controller:
    Enable seamless opening of tagged item URLs.
    Ensure proper handling of external links.
    
Maintenance & Cleanup
  Set up Cloud Functions:
    Automate:
      Cleaning up user data upon account deletion.
    
Hosting
  Set up Firebase Hosting:
    Serve app-specific links for shared posts.
    Create a homepage for users accessing the app from non-iOS platforms.

Firebase Structure:
Firestore Structure
users collection:
{
  "uid": "user123",
  "username": "fashionista",
  "email": "user123@gmail.com",
  "bio": "Love my outfits!",
  "profilePictureURL": "https://...",
  "followersCount": 100,
  "followingCount": 50,
  "isPrivateProfile": false,
  "createdAt": <timestamp>
}
posts subcollection under each user:
{
  "imageURL": "https://...",
  "caption": "OOTD at the park!",
  "taggedItems": [
    { "title": "Hat", "link": "https://hat.com" }
  ],
  "timestamp": <timestamp>,
  "userID": "user123"
}
Firebase Storage
profile_pictures/{uid}.jpg
OOTDPosts/{uniqueID}.jpg

  
