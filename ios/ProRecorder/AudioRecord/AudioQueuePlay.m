#import "AudioQueuePlay.h"
#import <AVFoundation/AVFoundation.h>

#define MIN_SIZE_PER_FRAME 1600
#define EVERY_READ_LENGTH 800 //每次从文件读取的长度
#define QUEUE_BUFFER_SIZE 4      //队列缓冲个数

#define HTTP_MODE 1
#define LOCAL_MODE  2

@interface AudioQueuePlay()<NSURLSessionDelegate> {
  AudioQueueRef audioQueue;                                 //音频播放队列
  AudioStreamBasicDescription _audioDescription;
  AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; //音频缓存
  BOOL audioQueueBufferUsed[QUEUE_BUFFER_SIZE];             //判断音频缓存是否在使用
  NSLock *sysnLock;
  OSStatus osState;
  FILE * file;
  SInt64 fileSize;
  Byte *pcmDataBuffer;
  SInt64 playLen;
  
  NSURLSessionDataTask *_dataTask;
  NSMutableArray *_dataArray;
  BOOL _firstData;
}

@property (nonatomic, assign) int dataMode;

@end

@implementation AudioQueuePlay

- (instancetype)init {
  if (self = [super init]) {
    [self initVarWithSampleRate:16000 bitPerSample:16 channel:1];
  }
  return self;
}


- (instancetype)initQueueWithSampleRate:(int)sampleRate bitPerSample:(int)bitPerSample channel:(int)channel {
  self = [super init];
  [self initVarWithSampleRate:sampleRate bitPerSample:bitPerSample channel:channel];
  return self;
}

- (void) initVarWithSampleRate:(int)sampleRate bitPerSample:(int)bitPerSample channel:(int)channel{
  _pcmFile = nil;
  _isPlaying = false;
  if (self) {
    sysnLock = [[NSLock alloc]init];
    _dataArray = [NSMutableArray new];
    self.isWav = YES;
    // 播放PCM使用
    if (_audioDescription.mSampleRate <= 0) {
      //设置音频参数
      _audioDescription.mSampleRate = sampleRate;//采样率
      _audioDescription.mFormatID = kAudioFormatLinearPCM;
      // 下面这个是保存音频数据的方式的说明，如可以根据大端字节序或小端字节序，浮点数或整数以及不同体位去保存数据
      _audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
      //1单声道 2双声道
      _audioDescription.mChannelsPerFrame = channel;
      //每一个packet一侦数据,每个数据包下的桢数，即每个数据包里面有多少桢
      _audioDescription.mFramesPerPacket = 1;
      //每个采样点16bit量化 语音每采样点占用位数
      _audioDescription.mBitsPerChannel = bitPerSample;
      _audioDescription.mBytesPerPacket = _audioDescription.mBytesPerFrame = (_audioDescription.mBitsPerChannel / 8) * _audioDescription.mChannelsPerFrame;
      //每个数据包的bytes总数，每桢的bytes数*每个数据包的桢数
      
    }
    AudioQueueNewOutput(&_audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)self, nil, nil, 0, &audioQueue);//使用player的内部线程播
    ////添加buffer区
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
      int result =  AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
      NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d",i,result);
    }
  }
}

- (void)resetPlay {
  if (audioQueue != nil) {
    AudioQueueReset(audioQueue);
  }
}

-(void)startQueua{
  AudioQueueStart(audioQueue, NULL);
  for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
  {
    [self readPCMAndPlay:audioQueue buffer:audioQueueBuffers[i]];
  }
}

-(BOOL)openFile {
  if( _pcmFile == nil ){
    return false;
  } else {
    file  = fopen([_pcmFile UTF8String], "r");
    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:_pcmFile error:nil] fileSize];
    if(file){
      BOOL isWav = [_pcmFile.pathExtension.lowercaseString hasSuffix:@".wav"];
      self.isWav = isWav;
      fseek(file, 0, isWav?44:SEEK_SET);
      if (self.isWav) {
        fileSize -= 44;
      }
      pcmDataBuffer = malloc(EVERY_READ_LENGTH);
    }
    return true;
  }
}

- (void)startDownloadFile {
  // 使用代理方法需要设置代理,但是session的delegate属性是只读的,要想设置代理只能通过这种方式创建session
  NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                        delegate:self
                                                   delegateQueue:[[NSOperationQueue alloc] init]];
  NSURL *url = [NSURL URLWithString:self.pcmFile];
//  if ([self.pcmFile.lowercaseString containsString:@".wav"]) {
//    self.isWav = YES;//HTTP url 中可能没有后缀名，默认是wav
//  }
  _dataTask = [session dataTaskWithRequest:[NSURLRequest requestWithURL:url]];
  [_dataTask resume];
}

-(void)play{
  NSLog(@"start play %@", self.pcmFile);
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  NSError *error;
  [audioSession setCategory:AVAudioSessionCategoryPlayback  error:&error];
  if(error){
    return ;
  }
  if ([self.pcmFile.lowercaseString hasPrefix:@"http"]) {
    _dataMode = HTTP_MODE;
    _firstData = NO;
    _isPlaying = true;
    playLen = 0;
//    [_delegate audioPlay:self didPlayStart: 1];
    [self notifyObservers:@selector(audioPlay:didPlayStart:) withObjects:self,@(1), nil];
    [self startDownloadFile];
  } else {
    _dataMode = LOCAL_MODE;
    if( [self openFile] ){
      playLen = 0;
      [self startQueua];
      _isPlaying = true;
//      [_delegate audioPlay:self didPlayStart: 1];
      [self notifyObservers:@selector(audioPlay:didPlayStart:) withObjects:self, @(1), nil];
    }
  }
}

-(void)stop{
  NSLog(@"stop play");
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback  error:nil];
    [audioSession setActive:NO error:nil];
  });
  if (file != NULL) {
    fclose(file);
    file = NULL;
  }
  if (_dataTask) {
    _dataTask = nil;
  }
  if (audioQueue != nil) {
    AudioQueueStop(audioQueue,true);
  }
  _isPlaying = false;
  pcmDataBuffer = NULL;
  for (int i=0; i<QUEUE_BUFFER_SIZE; i++) {
    AudioQueueBufferRef outQB = audioQueueBuffers[i];
    outQB->mUserData = NULL;
  }
  [_dataArray removeAllObjects];
//  [_delegate audioPlay:self didPlayStop: 1];
  [self notifyObservers:@selector(audioPlay:didPlayStop:) withObjects:self, @(1), nil];
}

- (void)dealloc {
  
  if (audioQueue != nil) {
    for (int i=0; i<QUEUE_BUFFER_SIZE; i++) {
      AudioQueueBufferRef outQB = audioQueueBuffers[i];
      outQB->mUserData = NULL;
      AudioQueueFreeBuffer(audioQueue, outQB);
    }
    AudioQueueDispose(audioQueue,true);
  }

  audioQueue = nil;
  sysnLock = nil;
  printf("dealloc...\n");
}

-(int)byteLenToMs:(SInt64)len{
  //return len / 2 / 16000 * 1000;
  return (int)(len / 32);
}

-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB
{
  [sysnLock lock];
  NSData * outData = [NSData dataWithBytes:outQB->mAudioData length:outQB->mAudioDataByteSize];
  playLen += outQB->mAudioDataByteSize;
//  [_delegate audioPlay:self playData: outData];
  [self notifyObservers:@selector(audioPlay:playData:) withObjects:self, outData, nil];
//  [_delegate audioPlay:self playProgress: [self byteLenToMs:playLen] totalMs: [self byteLenToMs:fileSize]];
  [self notifyObservers:@selector(audioPlay:playProgress:totalMs:) withObjects:self,@([self byteLenToMs:playLen]),@([self byteLenToMs:fileSize]), nil];
  if (file == NULL) {
    [sysnLock unlock];
    return;
  }
  SInt64 sizeToRead = EVERY_READ_LENGTH;
  if (fileSize - playLen < EVERY_READ_LENGTH) {
    sizeToRead = fileSize - playLen;
  }
  int readLength = (int)fread(pcmDataBuffer, 1, EVERY_READ_LENGTH, file);
  if(readLength == 0){
    NSLog(@"playlen = %lld, filesize=%lld", playLen, fileSize);
    free(pcmDataBuffer);
    [self stop];
  } else {
    outQB->mAudioDataByteSize = readLength;
    Byte *audiodata = (Byte *)outQB->mAudioData;
    for(int i=0;i<readLength/2;i++) {
      audiodata[i*2] = pcmDataBuffer[i*2];
      audiodata[i*2+1] = pcmDataBuffer[i*2+1];
    }
    AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
  }
  [sysnLock unlock];
}

- (void)onAudioQueueCallback:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB {
  if (self.dataMode == LOCAL_MODE) {
    [self readPCMAndPlay:outQ buffer:outQB];
  } else {
    
    NSData * outData = [NSData dataWithBytes:outQB->mAudioData length:outQB->mAudioDataByteSize];
    playLen += outQB->mAudioDataByteSize;
    //  [_delegate audioPlay:self playData: outData];
    [self notifyObservers:@selector(audioPlay:playData:) withObjects:self, outData, nil];
    //  [_delegate audioPlay:self playProgress: [self byteLenToMs:playLen] totalMs: [self byteLenToMs:fileSize]];
    [self notifyObservers:@selector(audioPlay:playProgress:totalMs:) withObjects:self, @([self byteLenToMs:playLen]),@([self byteLenToMs:fileSize]),nil];
    
    if (_dataArray.count > 0) {
      [sysnLock lock];
      NSData *curData = _dataArray.firstObject;
      [_dataArray removeObjectAtIndex:0];
      [sysnLock unlock];
      
      outQB->mAudioDataByteSize = (UInt32)curData.length;
      Byte *audiodata = (Byte *)outQB->mAudioData;
      pcmDataBuffer = (Byte *)curData.bytes;
      for(int i=0;i<curData.length/2;i++) {
        audiodata[i*2] = pcmDataBuffer[i*2];
        audiodata[i*2+1] = pcmDataBuffer[i*2+1];
      }
      AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
    } else {
      outQB->mUserData = NULL;
      if (playLen >= fileSize && self.isPlaying) {
        [self stop];
      }
    }
  }
}

static void AudioPlayerAQInputCallback(void *input, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
  AudioQueuePlay *mine = (__bridge AudioQueuePlay *)input;
  [mine onAudioQueueCallback:outQ buffer:outQB];
}

- (void)startPlayonlineData {
  for (int i=0; i<QUEUE_BUFFER_SIZE; i++) {
    AudioQueueBufferRef outQB = audioQueueBuffers[i];
    if (_dataArray.count == 0) {
      break;
    }
    if (outQB->mUserData == NULL) {
      [sysnLock lock];
      NSData *curData = _dataArray.firstObject;
      [_dataArray removeObjectAtIndex:0];
      [sysnLock unlock];
      
      outQB->mAudioDataByteSize = (UInt32)curData.length;
      Byte *audiodata = (Byte *)outQB->mAudioData;
      pcmDataBuffer = (Byte *)curData.bytes;
      for(int i=0;i<curData.length/2;i++) {
        audiodata[i*2] = pcmDataBuffer[i*2];
        audiodata[i*2+1] = pcmDataBuffer[i*2+1];
      }
      outQB->mUserData = (__bridge void * _Nullable)self;
      
      AudioQueueEnqueueBuffer(audioQueue, outQB, 0, NULL);
    }
  }
}

#pragma mark -------------------------------
#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
  NSLog(@"response = %@", response);
  //此处注意,不设置为allow,其它delegate methods将不被执行
  completionHandler(NSURLSessionResponseAllow);//这句必须要先执行。。。
  
  fileSize = response.expectedContentLength;
  if (fileSize < 0) {
    NSHTTPURLResponse *urlResp = (NSHTTPURLResponse *)response;
    NSString *rangeStr = [urlResp.allHeaderFields objectForKey:@"Content-Range"];
    if (rangeStr) {
      NSString *fileSizeStr = [rangeStr substringFromIndex:[rangeStr rangeOfString:@"/"].location+1];
      fileSize = fileSizeStr.longLongValue;
    }
  }
  NSLog(@"file total Size %lld", fileSize);
  if (self.isWav) {
    fileSize -= 44;
  }
}

//2.当接受到服务器返回的数据的时候调用,会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)downData{
  NSData *data = downData;
  if (!_firstData) {
    _firstData = YES;
    AudioQueueStart(audioQueue, NULL);
    if (self.isWav) {
      if (data.length < 44) {//这里逻辑不完善，如果第一次下载的数据不足44字节，第二次下载下来的数据有会有文件头部信息，这是脏数据应该去掉的。因为这种情况几乎不可能出现，就不考虑了。
        return;
      }
      data = [downData subdataWithRange:NSMakeRange(44, data.length-44)];
    }
  }
  if (!self.isPlaying) {
    return;
  }
  [sysnLock lock];
  int preCount = (int)_dataArray.count;
  if (data.length > EVERY_READ_LENGTH) {
    int count = (int)data.length/EVERY_READ_LENGTH;
    if (data.length % EVERY_READ_LENGTH > 0) {
      count++;
    }
    for (int i=0; i<count; i++) {
      int start = i*EVERY_READ_LENGTH;
      int len = EVERY_READ_LENGTH;
      if (data.length - start < EVERY_READ_LENGTH) {
        len = (int)data.length - start;
      }
      NSRange range = NSMakeRange(start, len);
      NSData *dat = [data subdataWithRange:range];
      [_dataArray addObject:dat];
    }
  } else {
    [_dataArray addObject:data];
  }
  [sysnLock unlock];
  
  if (preCount == 0&&_dataArray.count>0) {
    [self startPlayonlineData];
  }
}

//3.当整个请求结束的时候调用,error有值的话,那么说明请求失败
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
  NSLog(@"download file end");
  if (error) {
    NSLog(@"download error = %@", error);
    if (self.isPlaying) {
      [self stop];
    }
  }
}

@end
