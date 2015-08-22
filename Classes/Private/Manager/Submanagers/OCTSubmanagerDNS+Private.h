//
//  OCTSubmanagerDNS+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

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

@interface OCTSubmanagerDNS (Private) <OCTSubmanagerProtocol>

@end
