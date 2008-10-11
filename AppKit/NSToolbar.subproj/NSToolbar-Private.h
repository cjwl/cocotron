
@interface NSToolbar (Private)
-(id)_itemsWithIdentifiers:(NSArray*)identifiers;
-(id)_allowedToolbarItems;
-(id)_defaultToolbarItems;
-(id)_itemForItemIdentifier:(NSString*)identifier willBeInsertedIntoToolbar:(BOOL)toolbar;
@end