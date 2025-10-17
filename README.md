# neom_releases
neom_releases is a module within the Open Neom ecosystem, dedicated to managing the complex workflow
of uploading and positioning new releases. Its primary role is to serve as a user-friendly and highly
configurable interface for artists, producers, and researchers to publish their work,
whether it's a single song, an EP, an album, a podcast episode, or an audiobook chapter.

This module is the gateway for enriching the platform with new content while ensuring all
necessary metadata, files, and publishing details are correctly handled.
As a commercial module, its architecture is built upon the public, open-source principles
of Open Neom, demonstrating how a robust open core can support sophisticated
private functionalities. This module embodies the Tecnozenism philosophy by empowering
creators to consciously position their work in the digital world.

🌟 Features & Responsibilities
neom_releases provides a comprehensive, multi-step flow for uploading releases:
•	Release Type Selection: Guides users to choose the type of release they want to upload (ReleaseUploadType),
    with specific rules for unverified users (e.g., free single release only).
•	Owner Selection: Allows users to choose between publishing as a soloist or as a member of a band
    (ReleaseUploadBandOrSoloPage), with dynamic options based on their profile and roles.
•	Itemlist & Release Naming: Facilitates the naming and description of the release and the container
    Itemlist (ReleaseUploadItemlistNameDescPage, ReleaseUploadNameDescPage).
•	Content Upload & Processing:
    o	Manages the selection of media files (audio/PDF) for the release item.
    o	Integrates with neom_media_upload for file selection and neom_video_editor for video/audio processing.
    o	Validates file sizes, durations, and formats.
    o	Handles the upload of media files to a remote server.
•	Metadata & Preferences:
    o	Allows for the addition of metadata such as instruments used, genres, and a published year.
    o	Enables setting a publisher's place and specifying if the release should be auto-published.
    o	Provides options for setting digital and physical prices for the release items.
•	Summary & Submission:
    o	Displays a summary of all release details before final submission (ReleaseUploadSummaryPage).
    o	Handles the final submission process, including creating an Itemlist, inserting AppReleaseItems
        into Firestore, and creating a post on the timeline.
•	Push Notification Integration: Triggers push notifications to alert followers about the new release.

🛠 Technical Highlights / Why it Matters (for developers)
For developers, neom_releases serves as an excellent case study for:
•	Complex Multi-Step Flows: Demonstrates how to design and implement a sophisticated, multi-page user
    flow for a critical business function, with complex validation and state management across each step.
•	GetX for Advanced State Management: Utilizes GetX extensively in ReleaseUploadController for managing
    complex reactive state (Rx<AppReleaseItem>, RxList for items/genres/instruments, RxBool for flags)
    and orchestrating numerous asynchronous operations.
•	Service Layer Interaction: Shows seamless interaction with a wide range of core services
    (UserService, InstrumentService, MediaUploadService, MapsService, TimelineService, AudioLitePlayerService)
    through their defined interfaces, maintaining strong architectural separation.
•	Inter-Module Communication: Demonstrates how to effectively communicate with and consume functionalities
    from other specialized modules (neom_genres, neom_bands, neom_media_upload).
•	Firestore Data Modeling: Provides examples of how to model and persist a multi-layered
    data structure (e.g., Itemlist containing AppReleaseItems) in Firestore.
•	Role-Based Logic: Implements logic to adapt the UI and available options based on a user's
    verification level, user role, and app flavor (AppInUse).
•	Custom Animations: Uses the rubber package for custom bottom sheet animations in summary pages,
    enhancing the user experience.

How it Supports the Open Neom Initiative
neom_releases is a core part of the commercial value proposition. Its existence and the clarity
of its architecture directly support the Open Neom initiative by:
•	Demonstrating the Value of the Open Core: It serves as a prime example of a powerful commercial
    feature built entirely on top of the public, open-source modules (neom_core, neom_commons, etc.),
    proving the robustness and extensibility of the open core.
•	Providing a Target for Integration: Its architecture and dependencies provide a clear target
    for future open-source modules to integrate with.
•	Driving Platform Sustainability: It enables business models (e.g., digital/physical sales)
    that ensure the financial sustainability of the entire Open Neom ecosystem.

🚀 Usage
This module provides routes and UI components for the release upload flow, starting from ReleaseUploadPage.
It is typically accessible from the main application navigation (e.g., a "Create" button in neom_home)
and requires specific user roles to be fully functional.

📦 Dependencies
neom_releases relies on neom_core for core services, models, and routing constants, and on neom_commons for reusable
UI components and utilities. It also directly depends on percent_indicator for progress visualization.

🤝 Contributing
As a private module, direct contributions to neom_releases are not open yet.
However, its architecture and its dependencies on the Open Neom ecosystem provide
a clear direction for where the community can contribute to the public modules
to support and enable this and other future functionalities.

To understand the broader architectural context of Open Neom and how neom_releases fits into the overall
vision of Tecnozenism, please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning and engagement
possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
