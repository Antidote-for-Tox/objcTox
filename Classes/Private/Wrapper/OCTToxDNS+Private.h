// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTToxDNS.h"
#import <toxcore/toxdns/toxdns.h>

/**
 * toxdns functions
 */
extern void *(*_tox_dns3_new)(uint8_t *server_public_key);
extern void (*_tox_dns3_kill)(void *dns3_object);
extern int (*_tox_generate_dns3_string)(void *dns3_object, uint8_t *string, uint16_t string_max_len, uint32_t *request_id,
                                        uint8_t *name, uint8_t name_len);
extern int (*_tox_decrypt_dns3_TXT)(void *dns3_object, uint8_t *tox_id, uint8_t *id_record, uint32_t id_record_len,
                                    uint32_t request_id);

@interface OCTToxDNS (Private)

@property (assign, nonatomic) void *toxDNS3;

@end
