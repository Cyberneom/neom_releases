### 1.1.0 - Major Architectural Refactor & Specialization
This release represents a major architectural refactor for neom_releases, solidifying its role as the central module for managing the full lifecycle of release uploads within the Open Neom ecosystem. The primary focus has been on achieving greater modularity, testability, and a clear separation of concerns, in line with the overarching Clean Architecture principles.

Key Architectural & Feature Improvements:

Major Architectural Changes:

neom_releases is now a dedicated, self-contained module for all release upload processes, ensuring a clear separation of concerns from main modules.

Decoupling from neom_home:

The multi-step release upload flow and its related logic, previously integrated into neom_home or other main modules, have been entirely extracted and centralized here. This allows neom_home to focus on its primary role as the navigation hub.

Service-Oriented Architecture:

Controllers within neom_releases (e.g., ReleaseUploadController) now exclusively interact with core functionalities through their respective service interfaces (use_cases) defined in neom_core. This includes services like UserService, MediaUploadService, MapsService, BandService, and TimelineService.

This promotes the Dependency Inversion Principle (DIP), leading to significantly improved testability and flexibility by abstracting concrete implementations.

Module-Specific Translations:

Introduced ReleaseTranslationConstants to centralize and manage all UI text strings specific to release upload functionalities. This ensures improved localization, maintainability, and consistency with Open Neom's global strategy.

Examples of new translation keys include: releaseUpload, uploadYourReleaseItem, addedReleaseAppItem, appItemDurationShort, outOf, publishedYear, publisher, publishedDate, digitalPositioning, tapCoverToPreviewRelease, releaseUploadPostCaptionMsg1, releaseUploadPostCaptionMsg2, digitalSalesModel, digitalSalesModelMsg, physicalSalesModel, physicalSalesModelMsg, salesModelMsg, releaseUploadIntro, releaseUploadType, releaseUploadInstr, releaseUploadGenres, releaseUploadNameDesc, releaseUploadItemlistNameDesc1, releaseUploadItemlistNameDesc2, releaseUploadPLaceDate, releaseTitle, releaseDesc, releaseItemlistTitle, releaseItemlistDesc, releaseDuration, releasePreview, releasePrice, releasePriceMsg, addReleaseFile, changeReleaseFile, autoPublishing, autoEditing, autoPublishingEditingMsg, includesPhysical, specifyPublishingPlace, addReleaseCoverImg, submitRelease, submitReleaseMsg, initialPrice, digitalReleasePrice, physicalReleasePrice, appReleaseItemsQty, releaseItemDurationMsg, releaseItemNameMsg, releaseItemFileMsg, releaseUploadBandSelection, publishAsSoloist, myProject, digitalPositioningSuccess, freeSingleReleaseUploadMsg.

Centralized Release Management Logic:

neom_releases now fully encapsulates the multi-step flow for uploading and positioning releases, from file selection to final submission and post creation.

Enhanced Maintainability & Scalability:

As a dedicated and self-contained module, neom_releases is now easier to maintain, test, and extend for future release-related features.

This aligns perfectly with the overall architectural vision of Open Neom, fostering a more collaborative and efficient development environment.

Leverages Core Open Neom Modules:

Built upon neom_core for foundational services and neom_commons for reusable UI components and utilities, ensuring seamless integration within the ecosystem.