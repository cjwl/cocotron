NAME = Foundation

link_files = rm -rf $(1);\
	mkdir -p $(1);\
	(\
		cd $(1);\
		ln -s ../../../Foundation/NS*.$(2) .;\
		ln -s ../../../Foundation/NS**/CF*.$(2) .;\
		ln -s ../../../Foundation/NS**/NS*.$(2) .;\
		ln -s ../../../Foundation/xml/NS*.$(2) .;\
		ln -s ../../../Foundation/platform_posix/NS*.$(2) .;\
		ln -s ../../../Foundation/platform_linux/NS*.$(2) .;\
		ln -s ../../../Foundation/NSException/debugHelpers.$(2) .;\
		ln -s ../../../Foundation/NSString/unibuffer.$(2) .;\
		ln -s ../../../Foundation/NSObject/objc_size_alignment.$(2) .;\
		ln -s ../../../Foundation/NSObject/forwarding.$(2) .;\
		ln -s ../../../Foundation/NSNetService/bonjour.$(2) .;\
		ln -s ../../../CoreFoundation/CF*.$(2) .;\
		ln -s ../../../CFNetwork/CF*.$(2) .;\
	);\

provide_src_files = ${shell (\
	test -f .srcFiles || (\
		$(call link_files,$(SRC_DIR),m)\
		(\
			cd $(SRC_DIR);\
			test `uname -m` = "i686" && (\
				ln -s ../../../Foundation/NSObject/platform_linux/msgSendv-linux.s .;\
			);\
			test `uname -m` = "x86_64" && (\
				ln -s ../../../Foundation/NSObject/platform_linux/msgSendv-x64.m .;\
			);\
		);\
		$(call link_files,$(INCLUDE_DIR),h)\
		(\
			cd $(INCLUDE_DIR);\
			ln -s ../../../Foundation/Foundation*.h .;\
			ln -s ../../../Foundation/NSCharacterSet/bitmapRepresentation.h .;\
			ln -s ../../../CoreFoundation/CoreFoundation.h .;\
			ln -s ../../../CoreServices/CoreServices.h .;\
			ln -s . Foundation;\
			ln -s . CoreFoundation;\
			ln -s . CoreServices;\
			ln -s . CFNetwork;\
		);\
		touch .srcFiles;\
	);\
) > /dev/null}


STATIC_LIBS = $(GCC_LIB_DIR)/libobjc.a

include ../Makefiles/Makefile.framework
