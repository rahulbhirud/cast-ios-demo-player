// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MediaList.h"
#import "Media.h"

@interface MediaList () <NSXMLParserDelegate> {
  NSString *_path;
  NSMutableArray *_list;
}

@end

@implementation MediaList

- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    _path = path;
    _list = [[NSMutableArray alloc] init];
  }
  return self;

}

- (BOOL)load {
  [_list removeAllObjects];

  NSData *xmlData = [NSData dataWithContentsOfFile:_path];
  NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
  [xmlParser setDelegate:self];
  return [xmlParser parse];
}

- (NSUInteger)count {
  return [_list count];
}

- (Media *)itemAtIndex:(NSUInteger)index {
  return (Media *)[_list objectAtIndex:index];
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict {
  if ([elementName isEqualToString:@"media"]) {
    NSString *title = [attributeDict valueForKey:@"title"];
    NSString *artist = [attributeDict valueForKey:@"artist"];
    NSString *urlString = [attributeDict valueForKey:@"url"];
    NSString *mimeType = [attributeDict valueForKey:@"mimeType"];
    NSString *imageUrlString = [attributeDict valueForKey:@"imageUrl"];
    if (!title || !urlString || !mimeType) return;
    NSURL *imageUrl = nil;
    if (imageUrlString) {
      imageUrl = [NSURL URLWithString:imageUrlString];
    }

    Media *media = [[Media alloc] initWithTitle:title
                                         artist:artist
                                            url:[NSURL URLWithString:urlString]
                                       mimeType:mimeType
                                       imageURL:imageUrl];
    [_list addObject:media];
  }
}

@end
