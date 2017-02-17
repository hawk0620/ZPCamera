//
//  nsuserdefaults-macros.h
//  JKJBY
//
//  Created by pyleaf on 14-10-13.
//  Copyright (c) 2014年 pyleaf. All rights reserved.
//

#ifndef JKJBY_nsuserdefaults_macros_h
#define JKJBY_nsuserdefaults_macros_h


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

#define defaults()                          [NSUserDefaults standardUserDefaults]
#define defaults_init(dictionary)			[defaults() registerDefaults:dictionary]
#define defaults_save()                     [defaults() synchronize]
#define defaults_object(key)                [defaults() objectForKey:key]
#define defaults_set_object(key, object)    [defaults() setObject:object forKey:key]; defaults_save(); defaults_post_notification(key)
#define defaults_remove(key)				[defaults() removeObjectForKey:key]

#define defaults_object_from_notification(n) [n.userInfo objectForKey:@"value"]
#define defaults_observe_object(key, block) [[NSNotificationCenter defaultCenter] addObserverForName:key object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n){ block( defaults_object_from_notification(n) ); }]
#define defaults_post_notification(defaults_key) [[NSNotificationCenter defaultCenter] postNotificationName:defaults_key object:nil userInfo:@{ @"value" : defaults_object(defaults_key) }]

#endif
