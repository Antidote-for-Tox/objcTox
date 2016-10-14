// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

/**
 * Clients are encouraged to set this as the maximum length names for DNS can have.
 */
extern const NSUInteger kOCTToxDNSMaxRecommendedNameLength;

@class OCTToxDNS3Object;

/* How to use this api to make secure tox dns3 requests:
 *
 * 1. Get the public key of a server that supports tox dns3.
 * 2. Create OCTToxDNS object to create DNS requests and handle responses for that server.
 * 3. Use generateDNS3StringForName:maxStringLength: to generate a OCTToxDNS3Object on the name we want to query .
 * 4. Take object.generatedString and use it for your DNS request like this:
 * _4haaaaipr1o3mz0bxweox541airydbovqlbju51mb4p0ebxq.rlqdj4kkisbep2ks3fj2nvtmk4daduqiueabmexqva1jc._tox.utox.org
 * 5. The TXT in the DNS you receive should look like this:
 * v=tox3;id=2vgcxuycbuctvauik3plsv3d3aadv4zfjfhi3thaizwxinelrvigchv0ah3qjcsx5qhmaksb2lv2hm5cwbtx0yp
 * 6. Take the id string and use it with decryptDNS3Text:forObject: and the OCTToxDNS3Object corresponding to the
 * request we stored earlier to get the Tox id returned by the DNS server.
 */
@interface OCTToxDNS : NSObject

- (instancetype)init __unavailable;
+ (instancetype)new __unavailable;

/**
 * @param serverPublicKey Public key of a server OCTToxDNS will be pointing to. Length should be kOCTToxPublicKeyLength.
 */
- (instancetype)initWithServerPublicKey:(NSString *)serverPublicKey;

/* Generate a OCTToxDNS3Object with dns3 string of maxStringLength used to query the dns server
 * for a tox id registered to user with name.
 *
 * @param name Name of user to generate search string.
 * @param maxStringLength Max length of string that will be generated in OCTToxDNS3Object.
 *
 * @return nil on error. On success OCTToxDNS3Object object with passed name, generated string and requestId.
 */
- (OCTToxDNS3Object *)generateDNS3StringForName:(NSString *)name maxStringLength:(uint16_t)maxStringLength;

/* Decode and decrypt the text returned text into Tox ID.
 *
 * @param text Encrypted string that was received by querying dns server. It should look somewhat like this:
 * 2vgcxuycbuctvauik3plsv3d3aadv4zfjfhi3thaizwxinelrvigchv0ah3qjcsx5qhmaksb2lv2hm5cwbtx0yp
 * @param object Object generated by generateDNS3StringForName:maxStringLength: method.
 *
 * @return Decrypted Tox ID on success, nil on failure.
 */
- (NSString *)decryptDNS3Text:(NSString *)text forObject:(OCTToxDNS3Object *)object;

@end
