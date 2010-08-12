//
//  ALSource.m
//  ObjectAL
//
//  Created by Karl Stenerud on 15/12/09.
//
// Copyright 2009 Karl Stenerud
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
//
// Note: You are NOT required to make the license available from within your
// iPhone application. Including it in your project is sufficient.
//
// Attribution is not required, but appreciated :)
//

#import "ALSource.h"
#import "ObjectALMacros.h"
#import "ObjectAL.h"


@implementation ALSource

#pragma mark Object Management

+ (id) source
{
	return [[[self alloc] init] autorelease];
}

+ (id) sourceOnContext:(ALContext*) context
{
	return [[[self alloc] initOnContext:context] autorelease];
}

- (id) init
{
	return [self initOnContext:[ObjectAL sharedInstance].currentContext];
}

- (id) initOnContext:(ALContext*) contextIn
{
	if(nil != (self = [super init]))
	{
		context = [contextIn retain];
		@synchronized([ObjectAL sharedInstance])
		{
			ALContext* oldContext = [ObjectAL sharedInstance].currentContext;
			[ObjectAL sharedInstance].currentContext = context;
			sourceId = [ALWrapper genSource];
			[ObjectAL sharedInstance].currentContext = oldContext;
		}
		
		[context notifySourceInitializing:self];
		gain = [ALWrapper getSourcef:sourceId parameter:AL_GAIN];
	}
	return self;
}

- (void) dealloc
{
	[context notifySourceDeallocating:self];
	
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourceStop:sourceId];
		[ALWrapper sourcei:sourceId parameter:AL_BUFFER value:AL_NONE];
	}

	[buffer release];

	@synchronized([ObjectAL sharedInstance])
	{
		ALContext* oldContext = [ObjectAL sharedInstance].currentContext;
		[ObjectAL sharedInstance].currentContext = context;
		[ALWrapper deleteSource:sourceId];
		[ObjectAL sharedInstance].currentContext = oldContext;
	}
	[context release];

	[super dealloc];
}


#pragma mark Properties

- (ALBuffer*) buffer
{
	SYNCHRONIZED_OP(self)
	{
		return buffer;
	}
}

- (void) setBuffer:(ALBuffer *) value
{
	SYNCHRONIZED_OP(self)
	{
		[self stop];
		[buffer autorelease];
		buffer = [value retain];
		[ALWrapper sourcei:sourceId parameter:AL_BUFFER value:buffer.bufferId];
	}
}

- (int) buffersQueued
{
	return [ALWrapper getSourcei:sourceId parameter:AL_BUFFERS_QUEUED];
}

- (int) buffersProcessed
{
	return [ALWrapper getSourcei:sourceId parameter:AL_BUFFERS_PROCESSED];
}

- (float) coneInnerAngle
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_CONE_INNER_ANGLE];
	}
}

- (void) setConeInnerAngle:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_CONE_INNER_ANGLE value:value];
	}
}

- (float) coneOuterAngle
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_CONE_OUTER_ANGLE];
	}
}

- (void) setConeOuterAngle:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_CONE_OUTER_ANGLE value:value];
	}
}

- (float) coneOuterGain
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_CONE_OUTER_GAIN];
	}
}

- (void) setConeOuterGain:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_CONE_OUTER_GAIN value:value];
	}
}

@synthesize context;

- (ALVector) direction
{
	ALVector result;
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper getSource3f:sourceId parameter:AL_DIRECTION v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setDirection:(ALVector) value
{
	SYNCHRONIZED_OP_WITH_STRUCT(self)
	{
		[ALWrapper source3f:sourceId parameter:AL_DIRECTION v1:value.x v2:value.y v3:value.z];
	}
}

- (float) gain
{
	SYNCHRONIZED_OP(self)
	{
		return gain;
	}
}

- (void) setGain:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		gain = value;
		if(muted)
		{
			value = 0;
		}
		[ALWrapper sourcef:sourceId parameter:AL_GAIN value:value];
	}
}

@synthesize interruptible;

- (bool) looping
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_LOOPING];
	}
}

- (void) setLooping:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcei:sourceId parameter:AL_LOOPING value:value];
	}
}

- (float) maxDistance
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_MAX_DISTANCE];
	}
}

- (void) setMaxDistance:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_MAX_DISTANCE value:value];
	}
}

- (float) maxGain
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_MAX_GAIN];
	}
}

- (void) setMaxGain:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_MAX_GAIN value:value];
	}
}

- (float) minGain
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_MIN_GAIN];
	}
}

- (void) setMinGain:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_MIN_GAIN value:value];
	}
}

- (bool) muted
{
	SYNCHRONIZED_OP(self)
	{
		return muted;
	}
}

- (void) setMuted:(bool) value
{
	SYNCHRONIZED_OP(self)
	{
		muted = value;
		float resultingGain = muted ? 0 : gain;
		[ALWrapper sourcef:sourceId parameter:AL_GAIN value:resultingGain];
	}
}

- (float) offsetInBytes
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_BYTE_OFFSET];
	}
}

- (void) setOffsetInBytes:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_BYTE_OFFSET value:value];
	}
}

- (float) offsetInSamples
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_SAMPLE_OFFSET];
	}
}

- (void) setOffsetInSamples:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_SAMPLE_OFFSET value:value];
	}
}

- (float) offsetInSeconds
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_SEC_OFFSET];
	}
}

- (void) setOffsetInSeconds:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_SEC_OFFSET value:value];
	}
}

- (bool) paused
{
	return AL_PAUSED == self.state;
}

- (void) setPaused:(bool) shouldPause
{
	SYNCHRONIZED_OP(self)
	{
		if(shouldPause)
		{
			if(AL_PLAYING == self.state)
			{
				[ALWrapper sourcePause:sourceId];
			}
		}
		else
		{
			if(AL_PAUSED == self.state)
			{
				[ALWrapper sourcePlay:sourceId];
			}
		}
	}
}

- (float) pitch
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_PITCH];
	}
}

- (void) setPitch:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_PITCH value:value];
	}
}

- (bool) playing
{
	return AL_PLAYING == self.state;
}

- (ALPoint) position
{
	ALPoint result;
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper getSource3f:sourceId parameter:AL_POSITION v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setPosition:(ALPoint) value
{
	SYNCHRONIZED_OP_WITH_STRUCT(self)
	{
		[ALWrapper source3f:sourceId parameter:AL_POSITION v1:value.x v2:value.y v3:value.z];
	}
}

- (float) pan
{
	return self.position.x;
}

- (void) setPan:(float) value
{
	self.position = alpoint(value, 0, 0);
}

- (float) referenceDistance
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_REFERENCE_DISTANCE];
	}
}

- (void) setReferenceDistance:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_REFERENCE_DISTANCE value:value];
	}
}

- (float) rolloffFactor
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcef:sourceId parameter:AL_ROLLOFF_FACTOR];
	}
}

- (void) setRolloffFactor:(float) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcef:sourceId parameter:AL_ROLLOFF_FACTOR value:value];
	}
}

@synthesize sourceId;

- (int) sourceRelative
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_SOURCE_RELATIVE];
	}
}

- (void) setSourceRelative:(int) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcei:sourceId parameter:AL_SOURCE_RELATIVE value:value];
	}
}

- (int) sourceType
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_SOURCE_TYPE];
	}
}

- (void) setSourceType:(int) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcei:sourceId parameter:AL_SOURCE_TYPE value:value];
	}
}

- (int) state
{
	SYNCHRONIZED_OP(self)
	{
		return [ALWrapper getSourcei:sourceId parameter:AL_SOURCE_STATE];
	}
}

- (void) setState:(int) value
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourcei:sourceId parameter:AL_SOURCE_STATE value:value];
	}
}

- (ALVector) velocity
{
	ALVector result;
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper getSource3f:sourceId parameter:AL_VELOCITY v1:&result.x v2:&result.y v3:&result.z];
	}
	return result;
}

- (void) setVelocity:(ALVector) value
{
	SYNCHRONIZED_OP_WITH_STRUCT(self)
	{
		[ALWrapper source3f:sourceId parameter:AL_VELOCITY v1:value.x v2:value.y v3:value.z];
	}
}


#pragma mark Playback

- (void) preload:(ALBuffer*) bufferIn
{
	SYNCHRONIZED_OP(self)
	{
		if(self.playing || self.paused)
		{
			[self stop];
		}
	
		self.buffer = bufferIn;
	}
}

- (id<SoundSource>) play
{
	SYNCHRONIZED_OP(self)
	{
		if(self.playing)
		{
			if(!interruptible)
			{
				return nil;
			}
			[self stop];
		}
		
		if(self.paused)
		{
			[self stop];
		}
		
		[ALWrapper sourcePlay:sourceId];
	}
	return self;
}

- (id<SoundSource>) play:(ALBuffer*) bufferIn
{
	return [self play:bufferIn loop:NO];
}

- (id<SoundSource>) play:(ALBuffer*) bufferIn loop:(bool) loop
{
	SYNCHRONIZED_OP(self)
	{
		if(self.playing)
		{
			if(!interruptible)
			{
				return nil;
			}
			[self stop];
		}
		
		self.buffer = bufferIn;
		self.looping = loop;
		
		[ALWrapper sourcePlay:sourceId];
	}
	return self;
}

- (id<SoundSource>) play:(ALBuffer*) bufferIn gain:(float) gainIn pitch:(float) pitchIn pan:(float) panIn loop:(bool) loopIn
{
	SYNCHRONIZED_OP(self)
	{
		if(self.playing)
		{
			if(!interruptible)
			{
				return nil;
			}
			[self stop];
		}
		
		self.buffer = bufferIn;
		
		// Set gain, pitch, and pan
		self.gain = gainIn;
		self.pitch = pitchIn;
		self.pan = panIn;
		self.looping = loopIn;
		
		[ALWrapper sourcePlay:sourceId];
	}		
	return self;
}

- (void) stop
{
	SYNCHRONIZED_OP(self)
	{
		[ALWrapper sourceStop:sourceId];
		paused = NO;
	}
}

- (void) clear
{
	SYNCHRONIZED_OP(self)
	{
		[self stop];
		self.buffer = nil;
	}
}


#pragma mark Queued Playback

- (bool) queueBuffer:(ALBuffer*) bufferIn
{
	SYNCHRONIZED_OP(self)
	{
		if(AL_STATIC == self.state)
		{
			self.buffer = nil;
		}
		ALuint bufferId = bufferIn.bufferId;
		return [ALWrapper sourceQueueBuffers:sourceId numBuffers:1 bufferIds:&bufferId];
	}
}

- (bool) queueBuffers:(NSArray*) buffers
{
	SYNCHRONIZED_OP(self)
	{
		if(AL_STATIC == self.state)
		{
			self.buffer = nil;
		}
		int numBuffers = [buffers count];
		ALuint* bufferIds = malloc(sizeof(ALuint) * numBuffers);
		int i = 0;
		for(ALBuffer* buf in buffers)
		{
			bufferIds[i] = buf.bufferId;
		}
		bool result = [ALWrapper sourceQueueBuffers:sourceId numBuffers:numBuffers bufferIds:bufferIds];
		free(bufferIds);
		return result;
	}
}

- (bool) unqueueBuffer:(ALBuffer*) bufferIn
{
	SYNCHRONIZED_OP(self)
	{
		ALuint bufferId = bufferIn.bufferId;
		return [ALWrapper sourceUnqueueBuffers:sourceId numBuffers:1 bufferIds:&bufferId];
	}
}

- (bool) unqueueBuffers:(NSArray*) buffers
{
	SYNCHRONIZED_OP(self)
	{
		if(AL_STATIC == self.state)
		{
			self.buffer = nil;
		}
		int numBuffers = [buffers count];
		ALuint* bufferIds = malloc(sizeof(ALuint) * numBuffers);
		int i = 0;
		for(ALBuffer* buf in buffers)
		{
			bufferIds[i] = buf.bufferId;
		}
		bool result = [ALWrapper sourceUnqueueBuffers:sourceId numBuffers:numBuffers bufferIds:bufferIds];
		free(bufferIds);
		return result;
	}
}

#pragma mark Internal Use

- (bool) requestUnreserve:(bool) interrupt
{
	SYNCHRONIZED_OP(self)
	{
		if(self.playing)
		{
			if(!self.interruptible || !interrupt)
			{
				return NO;
			}
			[self stop];
		}
		self.buffer = nil;
	}
	return YES;
}


@end
