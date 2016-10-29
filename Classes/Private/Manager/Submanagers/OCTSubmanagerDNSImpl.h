// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTSubmanagerDNS.h"
#import "OCTSubmanagerProtocol.h"
#import "dns_sd.h"

extern DNSServiceErrorType (*_DNSServiceQueryRecord)(
    DNSServiceRef *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    const char *fullname,
    uint16_t rrtype,
    uint16_t rrclass,
    DNSServiceQueryRecordReply callBack,
    void *context);

extern DNSServiceErrorType (*_DNSServiceProcessResult)(DNSServiceRef sdRef);

extern void (*_DNSServiceRefDeallocate)(DNSServiceRef sdRef);


typedef void (^OCTDNSQueryCallback)(DNSServiceErrorType errorCode, NSData *data);

@interface OCTSubmanagerDNSImpl : NSObject <OCTSubmanagerDNS, OCTSubmanagerProtocol>

@end
