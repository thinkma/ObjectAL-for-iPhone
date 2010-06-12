//
//  OpenAL.m
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

#import "ALWrapper.h"


/**
 * Private interface to ALWrapper.
 */
@interface ALWrapper (Private)

/** Decode an OpenAL supplied NULL-separated string list into an NSArray.
 *
 * @param source the string list as supplied by OpenAL.
 * @return the string list in an NSArray of NSString.
 */
+ (NSArray*) decodeNullSeparatedStringList:(const ALCchar*) source;

/** Decode an OpenAL supplied space-separated string list into an NSArray.
 *
 * @param source the string list as supplied by OpenAL.
 * @return the string list in an NSArray of NSString.
 */
+ (NSArray*) decodeSpaceSeparatedStringList:(const ALCchar*) source;

@end

#pragma mark -

@implementation ALWrapper

static BOOL logErrors = TRUE;

typedef ALdouble AL_APIENTRY (*alcMacOSXGetMixerOutputRateProcPtr)();
typedef ALvoid AL_APIENTRY (*alcMacOSXMixerOutputRateProcPtr) (const ALdouble value);
typedef ALvoid	AL_APIENTRY	(*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, const ALvoid* data, ALsizei size, ALsizei freq);

static alcMacOSXGetMixerOutputRateProcPtr alcGetMacOSXMixerOutputRate = NULL;
static alcMacOSXMixerOutputRateProcPtr alcMacOSXMixerOutputRate = NULL;
static alBufferDataStaticProcPtr alBufferDataStatic = NULL;

#pragma mark -
#pragma mark Configuration

- (void) setLogErrorsEnabled:(BOOL) value
{
	logErrors = value;
}


#pragma mark -
#pragma mark Error Handling

/** Check the OpenAL error status and log an error message if necessary.
 *
 * @param contextInfo Contextual information to add when logging an error.
 * @return TRUE if the operation was successful (no error).
 */
BOOL checkIfSuccessful(NSString* contextInfo)
{
	ALenum error = alGetError();
	if(AL_NO_ERROR != error)
	{
		if(logErrors)
		{
			NSLog(@"Error: OpenAL: %@: %s (error code 0x%x)", contextInfo, alGetString(error), error);
		}
		return NO;
	}
	return YES;
}

/** Check the OpenAL error status and log an error message if necessary.
 *
 * @param contextInfo Contextual information to add when logging an error.
 * @param device The device to check for errors on.
 * @return TRUE if the operation was successful (no error).
 */
BOOL checkIfSuccessfulWithDevice(NSString* contextInfo, ALCdevice* device)
{
	ALenum error = alcGetError(device);
	if(ALC_NO_ERROR != error)
	{
		if(logErrors)
		{
			NSLog(@"Error: OpenAL: %@: %s (error code 0x%x)", contextInfo, alcGetString(device, error), error);
		}
		return NO;
	}
	return YES;
}


#pragma mark Internal Utility

+ (NSArray*) decodeNullSeparatedStringList:(const ALCchar*) source
{
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:10];
	NSString* lastString = nil;
	
	for(const ALCchar* nextString = source; 0 != *nextString; nextString += [lastString length] + 1)
	{
		lastString = [NSString stringWithFormat:@"%s", nextString];
	}
	
	return array;
}

+ (NSArray*) decodeSpaceSeparatedStringList:(const ALCchar*) source
{
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:10];
	ALCchar buffer[200];
	ALCchar* bufferPtr = buffer;
	const ALCchar* sourcePtr = source;

	for(;;)
	{
		*bufferPtr = *sourcePtr;
		if(' ' == *bufferPtr || bufferPtr >= buffer + 199)
		{
			*bufferPtr = 0;
		}
		if(0 == *bufferPtr)
		{
			[array addObject:[NSString stringWithFormat:@"%s", buffer]];
			bufferPtr = buffer;
		}
		else
		{
			bufferPtr++;
		}

		if(0 == *sourcePtr)
		{
			break;
		}

		sourcePtr++;
	}
	
	return array;
}


#pragma mark -
#pragma mark OpenAL Management

+ (bool) enable:(ALenum) capability
{
	bool result;
	@synchronized(self)
	{
		alEnable(capability);
		result = checkIfSuccessful(@"enable");
	}
	return result;
}

+ (bool) disable:(ALenum) capability
{
	bool result;
	@synchronized(self)
	{
		alDisable(capability);
		result = checkIfSuccessful(@"disable");
	}
	return result;
}

+ (bool) isEnabled:(ALenum) capability
{
	ALboolean result;
	@synchronized(self)
	{
		result = alIsEnabled(capability);
		checkIfSuccessful(@"isEnabled");
	}
	return result;
}


#pragma mark OpenAL Extensions

+ (bool) isExtensionPresent:(NSString*) extensionName
{
	ALboolean result;
	@synchronized(self)
	{
		result = alIsExtensionPresent([extensionName UTF8String]);
		checkIfSuccessful(@"isExtensionPresent");
	}
	return result;
}

+ (void*) getProcAddress:(NSString*) functionName
{
	void* result;
	@synchronized(self)
	{
		result = alGetProcAddress([functionName UTF8String]);
		checkIfSuccessful(@"getProcAddress");
	}
	return result;
}

+ (ALenum) getEnumValue:(NSString*) enumName
{
	ALenum result;
	@synchronized(self)
	{
		result = alGetEnumValue([enumName UTF8String]);
		checkIfSuccessful(@"getEnumValue");
	}
	return result;
}


#pragma mark -
#pragma mark Device Management

+ (ALCdevice*) openDevice:(NSString*) deviceName
{
	ALCdevice* device;
	@synchronized(self)
	{
		device = alcOpenDevice([deviceName UTF8String]);
		if(NULL == device)
		{
			NSLog(@"Error: OpenAL: openDevice:%@: Could not open device", deviceName);
		}
	}
	return device;
}

+ (bool) closeDevice:(ALCdevice*) device
{
	bool result;
	@synchronized(self)
	{
		alcCloseDevice(device);
		result = checkIfSuccessfulWithDevice(@"getEnumValue", device);
	}
	return result;
}


#pragma mark Device Extensions

+ (bool) isExtensionPresent:(ALCdevice*) device name:(NSString*) extensionName
{
	bool result;
	@synchronized(self)
	{
		result = alcIsExtensionPresent(device, [extensionName UTF8String]);
		checkIfSuccessfulWithDevice(@"isExtensionPresent", device);
	}
	return result;
}

+ (void*) getProcAddress:(ALCdevice*) device name:(NSString*) functionName
{
	void* result;
	@synchronized(self)
	{
		result = alcGetProcAddress(device, [functionName UTF8String]);
		checkIfSuccessfulWithDevice(@"getProcAddress", device);
	}
	return result;
}

+ (ALenum) getEnumValue:(ALCdevice*) device name:(NSString*) enumName
{
	ALenum result;
	@synchronized(self)
	{
		result = alcGetEnumValue(device, [enumName UTF8String]);
		checkIfSuccessfulWithDevice(@"getEnumValue", device);
	}
	return result;
}


#pragma mark Device Properties

+ (NSString*) getString:(ALCdevice*) device attribute:(ALenum) attribute
{
	const ALCchar* result;
	@synchronized(self)
	{
		result = alcGetString(device, attribute);
		checkIfSuccessfulWithDevice(@"getString", device);
	}
	return [NSString stringWithFormat:@"%s", result];
}

+ (NSArray*) getNullSeparatedStringList:(ALCdevice*) device attribute:(ALenum) attribute
{
	const ALCchar* result;
	@synchronized(self)
	{
		result = alcGetString(device, attribute);
		checkIfSuccessfulWithDevice(@"getNullSeparatedStringList", device);
	}
	return [self decodeNullSeparatedStringList:result];
}

+ (NSArray*) getSpaceSeparatedStringList:(ALCdevice*) device attribute:(ALenum) attribute
{
	const ALCchar* result;
	@synchronized(self)
	{
		result = alcGetString(device, attribute);
		checkIfSuccessfulWithDevice(@"getSpaceSeparatedStringList", device);
	}
	return [self decodeSpaceSeparatedStringList:result];
}

+ (ALint) getInteger:(ALCdevice*) device attribute:(ALenum) attribute
{
	ALint result = 0;
	[self getIntegerv:device attribute:attribute size:1 data:&result];
	return result;
}

+ (bool) getIntegerv:(ALCdevice*) device attribute:(ALenum) attribute size:(ALsizei) size data:(ALCint*) data
{
	bool result;
	@synchronized(self)
	{
		alcGetIntegerv(device, attribute, size, data);
		result = checkIfSuccessfulWithDevice(@"getIntegerv", device);
	}
	return result;
}


#pragma mark Capture

+ (ALCdevice*) openCaptureDevice:(NSString*) deviceName frequency:(ALCuint) frequency format:(ALCenum) format bufferSize:(ALCsizei) bufferSize
{
	ALCdevice* result;
	@synchronized(self)
	{
		result = alcCaptureOpenDevice([deviceName UTF8String], frequency, format, bufferSize);
		if(nil == result)
		{
			NSLog(@"Error: OpenAL: openCaptureDevice:%@: Could not open device", deviceName);
		}
	}
	return result;
}

+ (bool) closeCaptureDevice:(ALCdevice*) device
{
	bool result;
	@synchronized(self)
	{
		alcCaptureCloseDevice(device);
		result = checkIfSuccessfulWithDevice(@"closeCaptureDevice", device);
	}
	return result;
}

+ (bool) startCapture:(ALCdevice*) device
{
	bool result;
	@synchronized(self)
	{
		alcCaptureStop(device);
		result = checkIfSuccessfulWithDevice(@"startCapture", device);
	}
	return result;
}

+ (bool) stopCapture:(ALCdevice*) device
{
	bool result;
	@synchronized(self)
	{
		alcCaptureStop(device);
		result = checkIfSuccessfulWithDevice(@"stopCapture", device);
	}
	return result;
}

+ (bool) captureSamples:(ALCdevice*) device buffer:(ALCvoid*) buffer numSamples:(ALCsizei) numSamples
{
	bool result;
	@synchronized(self)
	{
		alcCaptureSamples(device, buffer, numSamples);
		result = checkIfSuccessfulWithDevice(@"captureSamples", device);
	}
	return result;
}


#pragma mark -
#pragma mark Context Management

+ (ALCcontext*) createContext:(ALCdevice*) device attributes:(ALCint*) attributes
{
	ALCcontext* result;
	@synchronized(self)
	{
		result = alcCreateContext(device, attributes);
		checkIfSuccessfulWithDevice(@"createContext", device);
	}
	return result;
}

+ (bool) makeContextCurrent:(ALCcontext*) context
{
	return [self makeContextCurrent:context deviceReference:nil];
}

+ (bool) makeContextCurrent:(ALCcontext*) context deviceReference:(ALCdevice*) deviceReference
{
	@synchronized(self)
	{
		if(!alcMakeContextCurrent(context))
		{
			if(nil != deviceReference)
			{
				checkIfSuccessfulWithDevice(@"makeContextCurrent", deviceReference);
			}
			else
			{
				NSLog(@"Error: OpenAL: makeContextCurrent: Could not make context %x current.  Pass in a device reference for better diagnostic info.");
			}
			return NO;
		}
	}
	return YES;
}

+ (void) processContext:(ALCcontext*) context
{
	@synchronized(self)
	{
		alcProcessContext(context);
		// No way to check for error from here
	}
}

+ (void) suspendContext:(ALCcontext*) context
{
	@synchronized(self)
	{
		alcSuspendContext(context);
		// No way to check for error from here
	}
}

+ (void) destroyContext:(ALCcontext*) context
{
	@synchronized(self)
	{
		alcDestroyContext(context);
		// No way to check for error from here
	}
}

+ (ALCcontext*) getCurrentContext
{
	ALCcontext* result;
	@synchronized(self)
	{
		result = alcGetCurrentContext();
	}
	return result;
}

+ (ALCdevice*) getContextsDevice:(ALCcontext*) context
{
	return [self getContextsDevice:context deviceReference:nil];
}

+ (ALCdevice*) getContextsDevice:(ALCcontext*) context deviceReference:(ALCdevice*) deviceReference
{
	ALCdevice* result;
	@synchronized(self)
	{
		if(nil == (result = alcGetContextsDevice(context)))
		{
			if(nil != deviceReference)
			{
				checkIfSuccessfulWithDevice(@"getContextsDevice", deviceReference);
			}
			else
			{
				NSLog(@"Error: OpenAL: getContextsDevice: Could not get device for context %x.  Pass in a device reference for better diagnostic info.");
			}
		}
	}
	return result;
}


#pragma mark Context Properties

+ (bool) getBoolean:(ALenum) parameter
{
	ALboolean result;
	@synchronized(self)
	{
		result = alGetBoolean(parameter);
		checkIfSuccessful(@"getBoolean");
	}
	return result;
}

+ (ALdouble) getDouble:(ALenum) parameter
{
	ALdouble result;
	@synchronized(self)
	{
		result = alGetDouble(parameter);
		checkIfSuccessful(@"getDouble");
	}
	return result;
}

+ (ALfloat) getFloat:(ALenum) parameter
{
	ALfloat result;
	@synchronized(self)
	{
		result = alGetFloat(parameter);
		checkIfSuccessful(@"getFloat");
	}
	return result;
}

+ (ALint) getInteger:(ALenum) parameter
{
	ALint result;
	@synchronized(self)
	{
		result = alGetInteger(parameter);
		checkIfSuccessful(@"getInteger");
	}
	return result;
}

+ (NSString*) getString:(ALenum) parameter
{
	const ALchar* result;
	@synchronized(self)
	{
		result = alGetString(parameter);
		checkIfSuccessful(@"getString");
	}
	return [NSString stringWithFormat:@"%s", result];
}

+ (NSArray*) getNullSeparatedStringList:(ALenum) parameter
{
	const ALchar* result;
	@synchronized(self)
	{
		result = alGetString(parameter);
		checkIfSuccessful(@"getNullSeparatedStringList");
	}
	return [self decodeNullSeparatedStringList:result];
}

+ (NSArray*) getSpaceSeparatedStringList:(ALenum) parameter
{
	const ALchar* result;
	@synchronized(self)
	{
		result = alGetString(parameter);
		checkIfSuccessful(@"getSpaceSeparatedStringList");
	}
	return [self decodeSpaceSeparatedStringList:result];
}

+ (bool) getBooleanv:(ALenum) parameter values:(ALboolean*) values
{
	bool result;
	@synchronized(self)
	{
		alGetBooleanv(parameter, values);
		result = checkIfSuccessful(@"getBooleanv");
	}
	return result;
}

+ (bool) getDoublev:(ALenum) parameter values:(ALdouble*) values
{
	bool result;
	@synchronized(self)
	{
		alGetDoublev(parameter, values);
		result = checkIfSuccessful(@"getDoublev");
	}
	return result;
}

+ (bool) getFloatv:(ALenum) parameter values:(ALfloat*) values
{
	bool result;
	@synchronized(self)
	{
		alGetFloatv(parameter, values);
		result = checkIfSuccessful(@"getFloatv");
	}
	return result;
}

+ (bool) getIntegerv:(ALenum) parameter values:(ALint*) values
{
	bool result;
	@synchronized(self)
	{
		alGetIntegerv(parameter, values);
		result = checkIfSuccessful(@"getIntegerv");
	}
	return result;
}

+ (bool) distanceModel:(ALenum) value
{
	bool result;
	@synchronized(self)
	{
		alDistanceModel(value);
		result = checkIfSuccessful(@"distanceModel");
	}
	return result;
}

+ (bool) dopplerFactor:(ALfloat) value
{
	bool result;
	@synchronized(self)
	{
		alDopplerFactor(value);
		result = checkIfSuccessful(@"dopplerFactor");
	}
	return result;
}

+ (bool) speedOfSound:(ALfloat) value
{
	bool result;
	@synchronized(self)
	{
		alSpeedOfSound(value);
		result = checkIfSuccessful(@"speedOfSound");
	}
	return result;
}


#pragma mark -
#pragma mark Listener Properties

+ (bool) listenerf:(ALenum) parameter value:(ALfloat) value
{
	bool result;
	@synchronized(self)
	{
		alListenerf(parameter, value);
		result = checkIfSuccessful(@"listenerf");
	}
	return result;
}

+ (bool) listener3f:(ALenum) parameter v1:(ALfloat) v1 v2:(ALfloat) v2 v3:(ALfloat) v3
{
	bool result;
	@synchronized(self)
	{
		alListener3f(parameter, v1, v2, v3);
		result = checkIfSuccessful(@"listener3f");
	}
	return result;
}

+ (bool) listenerfv:(ALenum) parameter values:(ALfloat*) values
{
	bool result;
	@synchronized(self)
	{
		alListenerfv(parameter, values);
		result = checkIfSuccessful(@"listenerfv");
	}
	return result;
}

+ (bool) listeneri:(ALenum) parameter value:(ALint) value
{
	bool result;
	@synchronized(self)
	{
		alListeneri(parameter, value);
		result = checkIfSuccessful(@"listeneri");
	}
	return result;
}

+ (bool) listener3i:(ALenum) parameter v1:(ALint) v1 v2:(ALint) v2 v3:(ALint) v3
{
	bool result;
	@synchronized(self)
	{
		alListener3i(parameter, v1, v2, v3);
		result = checkIfSuccessful(@"listener3i");
	}
	return result;
}

+ (bool) listeneriv:(ALenum) parameter values:(ALint*) values
{
	bool result;
	@synchronized(self)
	{
		alListeneriv(parameter, values);
		result = checkIfSuccessful(@"listeneriv");
	}
	return result;
}


+ (ALfloat) getListenerf:(ALenum) parameter
{
	ALfloat value;
	@synchronized(self)
	{
		alGetListenerf(parameter, &value);
		checkIfSuccessful(@"getListenerf");
	}
	return value;
}

+ (bool) getListener3f:(ALenum) parameter v1:(ALfloat*) v1 v2:(ALfloat*) v2 v3:(ALfloat*) v3
{
	bool result;
	@synchronized(self)
	{
		alGetListener3f(parameter, v1, v2, v3);
		result = checkIfSuccessful(@"getListener3f");
	}
	return result;
}

+ (bool) getListenerfv:(ALenum) parameter values:(ALfloat*) values
{
	bool result;
	@synchronized(self)
	{
		alGetListenerfv(parameter, values);
		result = checkIfSuccessful(@"getListenerfv");
	}
	return result;
}

+ (ALint) getListeneri:(ALenum) parameter
{
	ALint value;
	@synchronized(self)
	{
		alGetListeneri(parameter, &value);
		checkIfSuccessful(@"getListeneri");
	}
	return value;
}

+ (bool) getListener3i:(ALenum) parameter v1:(ALint*) v1 v2:(ALint*) v2 v3:(ALint*) v3
{
	bool result;
	@synchronized(self)
	{
		alGetListener3i(parameter, v1, v2, v3);
		result = checkIfSuccessful(@"getListener3i");
	}
	return result;
}

+ (bool) getListeneriv:(ALenum) parameter values:(ALint*) values
{
	bool result;
	@synchronized(self)
	{
		alGetListeneriv(parameter, values);
		result = checkIfSuccessful(@"getListeneriv");
	}
	return result;
}


#pragma mark -
#pragma mark Source Management

+ (bool) genSources:(ALuint*) sourceIds numSources:(ALsizei) numSources
{
	bool result;
	@synchronized(self)
	{
		alGenSources(numSources, sourceIds);
		result = checkIfSuccessful(@"genSources");
	}
	return result;
}

+ (ALuint) genSource
{
	uint sourceId;
	@synchronized(self)
	{
		[self genSources:&sourceId numSources:1];
		sourceId = checkIfSuccessful(@"genSource") ? sourceId : AL_INVALID;
	}
	return sourceId;
}

+ (bool) deleteSources:(ALuint*) sourceIds numSources:(ALsizei) numSources
{
	bool result;
	@synchronized(self)
	{
		alDeleteSources(numSources, sourceIds);
		result = checkIfSuccessful(@"deleteSources");
	}
	return result;
}

+ (bool) deleteSource:(ALuint) sourceId
{
	bool result;
	@synchronized(self)
	{
		[self deleteSources:&sourceId numSources:1];
		result = checkIfSuccessful(@"deleteSource");
	}
	return result;
}

+ (bool) isSource:(ALuint) sourceId
{
	bool result;
	@synchronized(self)
	{
		result = alIsSource(sourceId);
		checkIfSuccessful(@"isSource");
	}
	return result;
}


#pragma mark Source Properties

+ (bool) sourcef:(ALuint) sourceId parameter:(ALenum) parameter value:(ALfloat) value
{
	bool result;
	@synchronized(self)
	{
		alSourcef(sourceId, parameter, value);
		result = checkIfSuccessful(@"sourcef");
	}
	return result;
}

+ (bool) source3f:(ALuint) sourceId parameter:(ALenum) parameter v1:(ALfloat) v1 v2:(ALfloat) v2 v3:(ALfloat) v3
{
	bool result;
	@synchronized(self)
	{
		alSource3f(sourceId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"source3f");
	}
	return result;
}

+ (bool) sourcefv:(ALuint) sourceId parameter:(ALenum) parameter values:(ALfloat*) values
{
	bool result;
	@synchronized(self)
	{
		alSourcefv(sourceId, parameter, values);
		result = checkIfSuccessful(@"sourcefv");
	}
	return result;
}

+ (bool) sourcei:(ALuint) sourceId parameter:(ALenum) parameter value:(ALint) value
{
	bool result;
	@synchronized(self)
	{
		alSourcei(sourceId, parameter, value);
		result = checkIfSuccessful(@"sourcei");
	}
	return result;
}

+ (bool) source3i:(ALuint) sourceId parameter:(ALenum) parameter v1:(ALint) v1 v2:(ALint) v2 v3:(ALint) v3
{
	bool result;
	@synchronized(self)
	{
		alSource3i(sourceId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"source3i");
	}
	return result;
}

+ (bool) sourceiv:(ALuint) sourceId parameter:(ALenum) parameter values:(ALint*) values
{
	bool result;
	@synchronized(self)
	{
		alSourceiv(sourceId, parameter, values);
		result = checkIfSuccessful(@"sourceiv");
	}
	return result;
}


+ (ALfloat) getSourcef:(ALuint) sourceId parameter:(ALenum) parameter
{
	ALfloat value;
	@synchronized(self)
	{
		alGetSourcef(sourceId, parameter, &value);
		checkIfSuccessful(@"getSourcef");
	}
	return value;
}

+ (bool) getSource3f:(ALuint) sourceId parameter:(ALenum) parameter v1:(ALfloat*) v1 v2:(ALfloat*) v2 v3:(ALfloat*) v3
{
	bool result;
	@synchronized(self)
	{
		alGetSource3f(sourceId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"getSource3f");
	}
	return result;
}

+ (bool) getSourcefv:(ALuint) sourceId parameter:(ALenum) parameter values:(ALfloat*) values
{
	bool result;
	@synchronized(self)
	{
		alGetSourcefv(sourceId, parameter, values);
		result = checkIfSuccessful(@"getSourcefv");
	}
	return result;
}

+ (ALint) getSourcei:(ALuint) sourceId parameter:(ALenum) parameter
{
	ALint value;
	@synchronized(self)
	{
		alGetSourcei(sourceId, parameter, &value);
		checkIfSuccessful(@"getSourcei");
	}
	return value;
}

+ (bool) getSource3i:(ALuint) sourceId parameter:(ALenum) parameter v1:(ALint*) v1 v2:(ALint*) v2 v3:(ALint*) v3
{
	bool result;
	@synchronized(self)
	{
		alGetSource3i(sourceId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"getSource3i");
	}
	return result;
}

+ (bool) getSourceiv:(ALuint) sourceId parameter:(ALenum) parameter values:(ALint*) values
{
	bool result;
	@synchronized(self)
	{
		alGetSourceiv(sourceId, parameter, values);
		result = checkIfSuccessful(@"getSourceiv");
	}
	return result;
}


#pragma mark Source Playback

+ (bool) sourcePlay:(ALuint) sourceId
{
	bool result;
	@synchronized(self)
	{
		alSourcePlay(sourceId);
		result = checkIfSuccessful(@"sourcePlay");
	}
	return result;
}

+ (bool) sourcePlayv:(ALuint*) sourceIds numSources:(ALsizei) numSources
{
	bool result;
	@synchronized(self)
	{
		alSourcePlayv(numSources, sourceIds);
		result = checkIfSuccessful(@"sourcePlayv");
	}
	return result;
}

+ (bool) sourcePause:(ALuint) sourceId
{
	bool result;
	@synchronized(self)
	{
		alSourcePause(sourceId);
		result = checkIfSuccessful(@"sourcePause");
	}
	return result;
}

+ (bool) sourcePausev:(ALuint*) sourceIds numSources:(ALsizei) numSources
{
	bool result;
	@synchronized(self)
	{
		alSourcePausev(numSources, sourceIds);
		result = checkIfSuccessful(@"sourcePausev");
	}
	return result;
}

+ (bool) sourceStop:(ALuint) sourceId
{
	bool result;
	@synchronized(self)
	{
		alSourceStop(sourceId);
		result = checkIfSuccessful(@"sourceStop");
	}
	return result;
}

+ (bool) sourceStopv:(ALuint*) sourceIds numSources:(ALsizei) numSources
{
	bool result;
	@synchronized(self)
	{
		alSourceStopv(numSources, sourceIds);
		result = checkIfSuccessful(@"sourceStopv");
	}
	return result;
}

+ (bool) sourceRewind:(ALuint) sourceId
{
	bool result;
	@synchronized(self)
	{
		alSourceRewind(sourceId);
		result = checkIfSuccessful(@"sourceRewind");
	}
	return result;
}

+ (bool) sourceRewindv:(ALuint*) sourceIds numSources:(ALsizei) numSources
{
	bool result;
	@synchronized(self)
	{
		alSourceRewindv(numSources, sourceIds);
		result = checkIfSuccessful(@"sourceRewindv");
	}
	return result;
}

+ (bool) sourceQueueBuffers:(ALuint) sourceId numBuffers:(ALsizei) numBuffers bufferIds:(ALuint*) bufferIds
{
	bool result;
	@synchronized(self)
	{
		alSourceQueueBuffers(sourceId, numBuffers, bufferIds);
		result = checkIfSuccessful(@"sourceQueueBuffers");
	}
	return result;
}

+ (bool) sourceUnqueueBuffers:(ALuint) sourceId numBuffers:(ALsizei) numBuffers bufferIds:(ALuint*) bufferIds
{
	bool result;
	@synchronized(self)
	{
		alSourceUnqueueBuffers(sourceId, numBuffers, bufferIds);
		result = checkIfSuccessful(@"sourceUnqueueBuffers");
	}
	return result;
}


#pragma mark -
#pragma mark Buffer Management

+ (bool) genBuffers:(ALuint*) bufferIds numBuffers:(ALsizei) numBuffers
{
	bool result;
	@synchronized(self)
	{
		alGenBuffers(numBuffers, bufferIds);
		result = checkIfSuccessful(@"genBuffers");
	}
	return result;
}

+ (ALuint) genBuffer
{
	uint bufferId;
	@synchronized(self)
	{
		[self genBuffers:&bufferId numBuffers:1];
		bufferId = checkIfSuccessful(@"genBuffer") ? bufferId : AL_INVALID;
	}
	return bufferId;
}

+ (bool) deleteBuffers:(ALuint*) bufferIds numBuffers:(ALsizei) numBuffers
{
	bool result;
	@synchronized(self)
	{
		alDeleteBuffers(numBuffers, bufferIds);
		result = checkIfSuccessful(@"deleteBuffers");
	}
	return result;
}

+ (bool) deleteBuffer:(ALuint) bufferId
{
	bool result;
	@synchronized(self)
	{
		[self deleteBuffers:&bufferId numBuffers:1];
		result = checkIfSuccessful(@"deleteBuffer");
	}
	return result;
}

+ (bool) isBuffer:(ALuint) bufferId
{
	bool result;
	@synchronized(self)
	{
		result = alIsBuffer(bufferId);
		checkIfSuccessful(@"isBuffer");
	}
	return result;
}

+ (bool) bufferData:(ALuint) bufferId format:(ALenum) format data:(const ALvoid*) data size:(ALsizei) size frequency:(ALsizei) frequency
{
	bool result;
	@synchronized(self)
	{
		alBufferData(bufferId, format, data, size, frequency);
		result = checkIfSuccessful(@"bufferData");
	}
	return result;
}


#pragma mark Buffer Properties

+ (bool) bufferf:(ALuint) bufferId parameter:(ALenum) parameter value:(ALfloat) value
{
	bool result;
	@synchronized(self)
	{
		alBufferf(bufferId, parameter, value);
		result = checkIfSuccessful(@"bufferf");
	}
	return result;
}

+ (bool) buffer3f:(ALuint) bufferId parameter:(ALenum) parameter v1:(ALfloat) v1 v2:(ALfloat) v2 v3:(ALfloat) v3
{
	bool result;
	@synchronized(self)
	{
		alBuffer3f(bufferId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"buffer3f");
	}
	return result;
}

+ (bool) bufferfv:(ALuint) bufferId parameter:(ALenum) parameter values:(ALfloat*) values
{
	bool result;
	@synchronized(self)
	{
		alBufferfv(bufferId, parameter, values);
		result = checkIfSuccessful(@"bufferfv");
	}
	return result;
}

+ (bool) bufferi:(ALuint) bufferId parameter:(ALenum) parameter value:(ALint) value
{
	bool result;
	@synchronized(self)
	{
		alBufferi(bufferId, parameter, value);
		result = checkIfSuccessful(@"bufferi");
	}
	return result;
}

+ (bool) buffer3i:(ALuint) bufferId parameter:(ALenum) parameter v1:(ALint) v1 v2:(ALint) v2 v3:(ALint) v3
{
	bool result;
	@synchronized(self)
	{
		alBuffer3i(bufferId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"buffer3i");
	}
	return result;
}

+ (bool) bufferiv:(ALuint) bufferId parameter:(ALenum) parameter values:(ALint*) values
{
	bool result;
	@synchronized(self)
	{
		alBufferiv(bufferId, parameter, values);
		result = checkIfSuccessful(@"bufferiv");
	}
	return result;
}


+ (ALfloat) getBufferf:(ALuint) bufferId parameter:(ALenum) parameter
{
	ALfloat value;
	@synchronized(self)
	{
		alGetBufferf(bufferId, parameter, &value);
		checkIfSuccessful(@"getBufferf");
	}
	return value;
}

+ (bool) getBuffer3f:(ALuint) bufferId parameter:(ALenum) parameter v1:(ALfloat*) v1 v2:(ALfloat*) v2 v3:(ALfloat*) v3
{
	bool result;
	@synchronized(self)
	{
		alGetBuffer3f(bufferId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"getBuffer3f");
	}
	return result;
}

+ (bool) getBufferfv:(ALuint) bufferId parameter:(ALenum) parameter values:(ALfloat*) values
{
	bool result;
	@synchronized(self)
	{
		alGetBufferfv(bufferId, parameter, values);
		result = checkIfSuccessful(@"getBufferfv");
	}
	return result;
}

+ (ALint) getBufferi:(ALuint) bufferId parameter:(ALenum) parameter
{
	ALint value;
	@synchronized(self)
	{
		alGetBufferi(bufferId, parameter, &value);
		checkIfSuccessful(@"getBufferi");
	}
	return value;
}

+ (bool) getBuffer3i:(ALuint) bufferId parameter:(ALenum) parameter v1:(ALint*) v1 v2:(ALint*) v2 v3:(ALint*) v3
{
	bool result;
	@synchronized(self)
	{
		alGetBuffer3i(bufferId, parameter, v1, v2, v3);
		result = checkIfSuccessful(@"getBuffer3i");
	}
	return result;
}

+ (bool) getBufferiv:(ALuint) bufferId parameter:(ALenum) parameter values:(ALint*) values
{
	bool result;
	@synchronized(self)
	{
		alGetBufferiv(bufferId, parameter, values);
		result = checkIfSuccessful(@"getBufferiv");
	}
	return result;
}


#pragma mark -
#pragma mark Apple Extensions

+ (ALdouble) getMixerOutputDataRate
{
	if(NULL == alcGetMacOSXMixerOutputRate)
	{
		alcGetMacOSXMixerOutputRate = (alcMacOSXGetMixerOutputRateProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alcMacOSXGetMixerOutputRate");
		if(NULL == alcGetMacOSXMixerOutputRate)
		{
			NSLog(@"Error: ALWrapper: Could not get proc pointer for \"alcMacOSXMixerOutputRate\".");
		}
	}
	
	ALdouble result;
	@synchronized(self)
	{
		result = alcGetMacOSXMixerOutputRate();
		checkIfSuccessful(@"MixerOutputRate");
	}
	return result;
}

+ (void) setMixerOutputDataRate:(ALdouble) frequency
{
	if(NULL == alcMacOSXMixerOutputRate)
	{
		alcMacOSXMixerOutputRate = (alcMacOSXMixerOutputRateProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alcMacOSXMixerOutputRate");
		if(NULL == alcMacOSXMixerOutputRate)
		{
			NSLog(@"Error: ALWrapper: Could not get proc pointer for \"alcMacOSXMixerOutputRate\".");
		}
	}
	
	alcMacOSXMixerOutputRate(frequency);
}

+ (bool) bufferDataStatic:(ALuint) bufferId format:(ALenum) format data:(const ALvoid*) data size:(ALsizei) size frequency:(ALsizei) frequency
{
	if(NULL == alBufferDataStatic)
	{
		alBufferDataStatic = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
		if(NULL == alBufferDataStatic)
		{
			NSLog(@"Error: ALWrapper: Could not get proc pointer for \"alBufferDataStatic\".");
		}
	}
	
	bool result;
	@synchronized(self)
	{
		alBufferDataStatic(bufferId, format, data, size, frequency);
		result = checkIfSuccessful(@"bufferDataStatic");
	}
	return result;
}

@end
