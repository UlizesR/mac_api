// mac_view.m
#import "MAC/mac_view.h"
#import "MAC/mac_window.h"

@implementation Mac_NSView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    // You can add custom drawing code for this view here.
}

@end

Mac_View* addSubView(Mac_View* parent, int width, int height, int x, int y, MAC_Color background_color) {
    Mac_View* view = (Mac_View*)malloc(sizeof(Mac_View));
    view->parent_view = parent;
    view->window_parent = parent->window_parent;
    view->width = width;
    view->height = height;
    view->x = x;
    view->y = y;
    view->background_color = background_color;
    view->is_root = false;
    view->is_metal_view = false;

    Mac_NSView* nsView = [[Mac_NSView alloc] initWithFrame:NSMakeRect(x, y, width, height)];
    [nsView setWantsLayer:YES];
    [nsView.layer setBackgroundColor:CGColorCreateGenericRGB(background_color.r, background_color.g, background_color.b, background_color.a)];

    // Assign the Mac_NSView instance to the _this member of the Mac_View struct
    view->_this = (__bridge void *)(nsView);

    NSView* parentNSView = nil;
    if (parent->is_root) {
        Mac_WindowDelegate* delegate = (__bridge Mac_WindowDelegate*)parent->window_parent->delegate;
        parentNSView = delegate.contentView;
    } else {
        parentNSView = (__bridge NSView*)parent->parent_view;
    }
    [parentNSView addSubview:nsView];

    if (g_viewCount < MAX_VIEWS) {
        g_views[g_viewCount++] = view;
    }

    return view;
}

Mac_View* addContentView(MAC_Window* parent, MAC_Color background_color) {
    Mac_View* view = (Mac_View*)malloc(sizeof(Mac_View));
    view->parent_view = NULL;
    view->window_parent = parent;
    view->width = parent->width;
    view->height = parent->height;
    view->x = 0;
    view->y = 0;
    view->background_color = background_color;
    view->is_root = true;
    view->is_metal_view = false;

    Mac_NSView* nsView = [[Mac_NSView alloc] initWithFrame:NSMakeRect(0, 0, view->width, view->height)];
    [nsView setWantsLayer:YES];
    [nsView.layer setBackgroundColor:CGColorCreateGenericRGB(background_color.r, background_color.g, background_color.b, background_color.a)];

    // Assign the Mac_NSView instance to the _this member of the Mac_View struct
    view->_this = (__bridge void *)(nsView);

    Mac_WindowDelegate* delegate = (__bridge Mac_WindowDelegate*)parent->delegate;
    [delegate.contentView addSubview:nsView];
    [nsView setNeedsDisplay:YES];

    if (g_viewCount < MAX_VIEWS) {
        g_views[g_viewCount++] = view;
    }

    return view;
}

void destroyView(Mac_View* view) {
    Mac_WindowDelegate* delegate = (__bridge Mac_WindowDelegate*)view->window_parent->delegate;
    for (NSView* subview in delegate.contentView.subviews) {
        if ([subview isKindOfClass:[Mac_NSView class]]) {
            [subview removeFromSuperview];
        }
    }
    free(view);
}

void destroyViews(Mac_View* views[], int count) {
    for (int i = 0; i < count; i++) {
        destroyView(views[i]);
    }
}