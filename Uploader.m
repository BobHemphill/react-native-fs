#import "Uploader.h"

@implementation RNFSUploadParams

@end

@interface RNFSUploader()

@property (copy) RNFSUploadParams* params;

@property (retain) NSURLSessionDataTask* task;

@end

@implementation RNFSUploader

- (void)uploadFiles:(RNFSUploadParams*)params
{
  _params = params;

  NSString *method = _params.method;
  NSURL *url = [NSURL URLWithString:_params.toUrl];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
  [req setHTTPMethod:method];

  // set headers
  NSString *contentType = @"video/mp4";
  NSString *amzAcl = @"bucket-owner-full-control";
  [req setValue:contentType forHTTPHeaderField:@"Content-Type"];
  [req setValue:amzAcl forHTTPHeaderField:@"x-amz-acl"];
  // add file
  NSDictionary *file = [_params.files objectAtIndex:0];
  NSString *filepath = file[@"filepath"];
    
//  NSFileManager *fileManager = [NSFileManager defaultManager];
//  if (![fileManager fileExistsAtPath:filepath]){
//    NSLog(@"Failed to open target file at path: %@", filepath);
//    NSError* error = [NSError errorWithDomain:@"Uploader" code:NSURLErrorFileDoesNotExist userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"Failed to open target file at path: %@", filepath]}];
//    return _params.errorCallback(error);
//  }
  // send request
  NSURL *fileUrl = [NSURL fileURLWithPath:filepath];
  NSString *uuid = [[NSUUID UUID] UUIDString];
  NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:uuid];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:(id)self delegateQueue:[NSOperationQueue mainQueue]];
    _task = [session uploadTaskWithRequest:req fromFile:fileUrl];
    [_task resume];
  _params.beginCallback();
}

- (NSString *)generateBoundaryString
{
  NSString *uuid = [[NSUUID UUID] UUIDString];
  return [NSString stringWithFormat:@"----%@", uuid];
}

- (NSString *)mimeTypeForPath:(NSString *)filepath
{
  NSString *fileExtension = [filepath pathExtension];
  NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
  NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);

  if (contentType) {
    return contentType;
  }
  return @"application/octet-stream";
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  if(error != nil) {
    return _params.errorCallback(error);
  }
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
   return _params.completeCallback(nil, httpResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
  return _params.progressCallback([NSNumber numberWithLongLong:totalBytesExpectedToSend], [NSNumber numberWithLongLong:totalBytesSent]);
}

- (void)stopUpload
{
  [_task cancel];
}

@end
