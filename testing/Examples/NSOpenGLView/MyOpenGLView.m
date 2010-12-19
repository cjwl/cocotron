#import "MyOpenGLView.h"
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation MyOpenGLView

-(void)awakeFromNib {
   _angleX=360;
   _timer=[[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(timer:) userInfo:nil repeats:YES] retain];
   [[self window] setTitle:NSLocalizedString(@"WindowTitle",@"")];
}

static void drawArcWithDepth(float beginAngle,float endAngle,float innerRadius,float outerRadius,float z){
   for(;beginAngle<=endAngle;beginAngle+=1){
    CGAffineTransform matrix=CGAffineTransformMakeRotation(M_PI*beginAngle/180.0);
    CGPoint           innerPoint=CGPointMake(innerRadius,0);
    CGPoint           outerPoint=CGPointMake(outerRadius,0);

    innerPoint=CGPointApplyAffineTransform(innerPoint,matrix);
    outerPoint=CGPointApplyAffineTransform(outerPoint,matrix);
    
    glVertex3f(innerPoint.x,innerPoint.y,z);
    glVertex3f(outerPoint.x,outerPoint.y,z);
   }
}

static void drawEdge(float beginAngle,float endAngle,float radius,float zclose,float zfar){
   for(;beginAngle<=endAngle;beginAngle+=1){
    CGAffineTransform matrix=CGAffineTransformMakeRotation(M_PI*beginAngle/180.0);
    CGPoint           point=CGPointMake(radius,0);
    CGPoint           normal=CGPointMake(1,0);
    
    point=CGPointApplyAffineTransform(point,matrix);
    normal=CGPointApplyAffineTransform(normal,matrix);
    
    glNormal3f(normal.x,normal.y,0);
    glVertex3f(point.x, point.y,zclose);
    glVertex3f(point.x, point.y,zfar);
   }
}

static void capAtAngle(float angle,float innerRadius,float outerRadius,float depth){
    CGAffineTransform matrix=CGAffineTransformMakeRotation(M_PI*angle/180.0);
    CGPoint           innerPoint=CGPointMake(innerRadius,0);
    CGPoint           outerPoint=CGPointMake(outerRadius,0);
    CGPoint           normal=CGPointMake(1,0);

    innerPoint=CGPointApplyAffineTransform(innerPoint,matrix);
    outerPoint=CGPointApplyAffineTransform(outerPoint,matrix);
    normal=CGPointApplyAffineTransform(normal,matrix);

    glNormal3f(normal.x,normal.y,0);

    glVertex3f(innerPoint.x, innerPoint.y,depth/2);
    glVertex3f(outerPoint.x, outerPoint.y,depth/2);
    glVertex3f(outerPoint.x, outerPoint.y,-depth/2);
    glVertex3f(innerPoint.x, innerPoint.y,-depth/2);
}

static void drawArc(float beginAngle,float endAngle,float innerRadius,float outerRadius,float depth){
   glNormal3f(1,0,0);
   glBegin(GL_QUAD_STRIP);
   drawArcWithDepth(beginAngle,endAngle,innerRadius,outerRadius,depth/2);
   glEnd();

   glNormal3f(-1,0,0);
   glBegin(GL_QUAD_STRIP);
   drawArcWithDepth(beginAngle,endAngle,innerRadius,outerRadius,-depth/2);
   glEnd();

   glColor3f(.2, .2, .2);

   glBegin(GL_QUAD_STRIP);
   drawEdge(beginAngle,endAngle,outerRadius,depth/2,-depth/2);
   glEnd();

   glBegin(GL_QUAD_STRIP);
   drawEdge(beginAngle,endAngle,innerRadius,depth/2,-depth/2);
   glEnd();

   glBegin(GL_QUADS);
   capAtAngle(beginAngle,innerRadius,outerRadius,depth);
   capAtAngle(endAngle,innerRadius,outerRadius,depth);
   glEnd();
}

static void drawCocotron(){
	glColor3f(0, 0, 0);
	drawArc(0,60,.5,1,.3);

	glColor3f(0, 0, 0);
	drawArc(120,180,.5,1,.3);

	glColor3f(0, 0, 0);
	drawArc(240,300,.5,1,.3);

	glColor3f(.5, .5, 0);
	drawArc(30,330,.2,.4,.3);
}

-(void)drawRect:(NSRect)bounds {   
	glClearColor(.3, 0, .3, 1);
	glLoadIdentity();
	glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT+GL_STENCIL_BUFFER_BIT);
    glRotatef(_angleX,0,1,0);
    drawCocotron();
    glFlush();
  [[self openGLContext] flushBuffer];
}

-(void)prepareOpenGL {
    glEnable(GL_DEPTH_TEST);
    glShadeModel(GL_SMOOTH);
}

-(void)reshape {
   glViewport(0,0,[self bounds].size.width,[self bounds].size.height);
}

-(void) timer:(NSTimer *)timer {
   _angleX -= 1;

   if(_angleX<0)
    _angleX=360;
        
   [self setNeedsDisplay:YES];
}

@end
