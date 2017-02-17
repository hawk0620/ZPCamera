// Copyright (c) 2012, Matthias Hochgatterer <matthias.hochgatterer@gmail.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#import <Foundation/Foundation.h>

#define SI static inline

SI void __defaults_post_notification(NSString *key);
SI void __defaults_save();

/*
	Returns the standard user defaults.
 */
SI NSUserDefaults *defaults() {
    return [NSUserDefaults standardUserDefaults];
}

/*
	Sets the default values.
 */
SI void defaults_init(NSDictionary *dictionary) {
    [defaults() registerDefaults:dictionary];
}

/*
	Returns the value with key from the user defaults.
 */
SI id defaults_object(NSString *key) {
    return [defaults() objectForKey:key];
}

/*
	Saves a value by key to the user defaults.
 */
SI void defaults_set_object(NSString *key, NSObject *object) {
    [defaults() setObject:object forKey:key];
    __defaults_save();
    __defaults_post_notification(key);
}

/*
	Removes the value for a specific key from the user defaults.
 */
SI void defaults_remove(NSString *key) {
    [defaults() removeObjectForKey:key];
    __defaults_save();
    __defaults_post_notification(key);
}

/*
	Observes a key with a callback queue.
	
	E.g. defaults_observe(@"user/email", ^(NSString *email){
	...
	});
 */
SI void defaults_observe(NSString *key, void (^block) (id object)) {
    [[NSNotificationCenter defaultCenter] addObserverForName:key object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n){
        block( [n.userInfo objectForKey:@"value"] );
    }];
}

/*
	Restores to the default values which where set with defaults_init(...)
 */
SI void defaults_restore(){
    
}

/*
	Completely resets the NSUserDefaults.
 */
SI void defaults_reset(){
    NSDictionary *defaultsDictionary = [defaults() dictionaryRepresentation];
    for (NSString *key in [defaultsDictionary allKeys]) {
        defaults_remove(key);
    }
}

// PRIVATE
SI void __defaults_post_notification(NSString *key) {
    id object = defaults_object(key);
    [[NSNotificationCenter defaultCenter] postNotificationName:key object:nil userInfo: object ? [NSDictionary dictionaryWithObject:object forKey:@"value"] : [NSDictionary dictionary]];
}

SI void __defaults_save() {
    [defaults() synchronize]; 
}