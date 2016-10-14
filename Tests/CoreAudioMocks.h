// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#define PATCH_FAILING(funcname) funcname = (void *)FAILING ## funcname
#define PATCH_PASSING(funcname) funcname = (void *)PASSING ## funcname

// Restores all the CoreAudio function pointers to passing.
#define RESTORE_PATCHES \
    PATCH_PASSING(_AudioQueueAllocateBuffer); \
    PATCH_PASSING(_AudioQueueDispose); \
    PATCH_PASSING(_AudioQueueEnqueueBuffer); \
    PATCH_PASSING(_AudioQueueFreeBuffer); \
    PATCH_PASSING(_AudioQueueNewInput); \
    PATCH_PASSING(_AudioQueueNewOutput); \
    PATCH_PASSING(_AudioQueueSetProperty); \
    PATCH_PASSING(_AudioQueueStart); \
    PATCH_PASSING(_AudioQueueStop);

// Implements a function named PASSING<funcname> that takes any number of args
// and just returns 0. Handy when there's no need for special functionality.
// They are not exactly valid C but it works for now (OS X 10.11.1, 64 bit)
#define DECLARE_GENERIC_PASS(funcname) OSStatus PASSING ## funcname(void *a, ...) { return 0; }
// Same, but return a failing error code.
#define DECLARE_GENERIC_FAIL(funcname) OSStatus FAILING ## funcname(void *a, ...) { return -1; }
