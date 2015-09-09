/*
 
 BaseDataModelObject.m
 debugDescription

 Copyright (c) 2015, Samantha Marshall
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.
 
 3. Neither the name of Samantha Marshall nor the names of its contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
*/

#import "BaseDataModelObject.h"
#include <objc/runtime.h>

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc-arc
#else

#define ATR_PACK __attribute__((packed))

#define GetDigitsOfNumber(num) (num > 0 ? (int)log10(num) + 1 : 1)

struct Range {
	uint64_t offset;
	uint64_t length;
} ATR_PACK Range;

typedef struct Range CoreRange;

#define CoreRangeCreate(offset, length) \
	(CoreRange)                         \
	{                                   \
		offset, length                  \
	}
#define CoreRangeContainsValue(range, value) (value >= range.offset && value < (range.offet + range.length))

typedef uintptr_t *Pointer;

#define k32BitMask 0xffffffff
#define k64BitMask 0xffffffffffffffff
#define k64BitMaskHigh 0xffffffff00000000
#define k64BitMaskLow 0x00000000ffffffff

#define Ptr(ptr) PtrCast(ptr, char *)
#define PtrCast(ptr, cast) ((cast)ptr)
#define PtrAdd(ptr, add) (Ptr(ptr) + (uint64_t)add)

#define kObjcCharEncoding "c"
#define kObjcIntEncoding "i"
#define kObjcShortEncoding "s"
#define kObjcLongEncoding "l"
#define kObjcLLongEncoding "q"
#define kObjcUCharEncoding "C"
#define kObjcUIntEncoding "I"
#define kObjcUShortEncoding "S"
#define kObjcULongEncoding "L"
#define kObjcULLongEncoding "Q"
#define kObjcFloatEncoding "f"
#define kObjcDoubleEncoding "d"
#define kObjcBoolEncoding "B"
#define kObjcVoidEncoding "v"
#define kObjcStringEncoding "*"
#define kObjcIdEncoding "@"
#define kObjcClassEncoding "#"
#define kObjcSelEncoding ":"
#define kObjcBitEncoding "b"
#define kObjcPointerEncoding "^"
#define kObjcUnknownEncoding "?"

#define kObjcConstEncoding "r"
#define kObjcInEncoding "n"
#define kObjcInOutEncoding "N"
#define kObjcOutEncoding "o"
#define kObjcByCopyEncoding "O"
#define kObjcByRefEncoding "R"
#define kObjcOnewayEncoding "V"

#define kObjcTypeEncodingCount 21

static char *ObjcTypeEncoding[kObjcTypeEncodingCount] = {
	kObjcCharEncoding,
	kObjcIntEncoding,
	kObjcShortEncoding,
	kObjcLongEncoding,
	kObjcLLongEncoding,
	kObjcUCharEncoding,
	kObjcUIntEncoding,
	kObjcUShortEncoding,
	kObjcULongEncoding,
	kObjcULLongEncoding,
	kObjcFloatEncoding,
	kObjcDoubleEncoding,
	kObjcBoolEncoding,
	kObjcVoidEncoding,
	kObjcStringEncoding,
	kObjcIdEncoding,
	kObjcClassEncoding,
	kObjcSelEncoding,
	kObjcBitEncoding,
	kObjcPointerEncoding,
	kObjcUnknownEncoding};

static char *ObjcTypeEncodingNames[kObjcTypeEncodingCount] = {
	"char",
	"int",
	"short",
	"long",
	"long long",
	"unsigned char",
	"unsigned int",
	"unsigned short",
	"unsigned long",
	"unsigned long long",
	"float",
	"double",
	"bool",
	"void",
	"char*",
	"id",
	"Class",
	"SEL",
	"bitmask",
	"*",
	"UnknownType"};

#define CHAR_HEX_DISPLAY 0

static char *ObjcTypeFormatter[kObjcTypeEncodingCount] = {
#if CHAR_HEX_DISPLAY
	"%x",
#else
	"%c",
#endif
	"%i",
	"%hi",
	"%ld",
	"%lld",
	"%hhu",
#if CHAR_HEX_DISPLAY
	"%x",
#else
	"%u",
#endif
	"%hu",
	"%lu",
	"%llu",
	"%f",
	"%f",
	"%i",
	"%p",
	"%s",
	"%@",
	"%p",
	"%s",
	"%i",
	"%p",
	"%p"};

enum LoaderObjcLexerTokenType {
	ObjcCharEncoding,
	ObjcIntEncoding,
	ObjcShortEncoding,
	ObjcLongEncoding,
	ObjcLLongEncoding,
	ObjcUCharEncoding,
	ObjcUIntEncoding,
	ObjcUShortEncoding,
	ObjcULongEncoding,
	ObjcULLongEncoding,
	ObjcFloatEncoding,
	ObjcDoubleEncoding,
	ObjcBoolEncoding,
	ObjcVoidEncoding,
	ObjcStringEncoding,
	ObjcIdEncoding,
	ObjcClassEncoding,
	ObjcSelEncoding,
	ObjcBitEncoding,
	ObjcPointerEncoding,
	ObjcUnknownEncoding,
	ObjcStructEncoding,
	ObjcArrayEncoding
};

#define kObjcNameTokenStart "\""
#define kObjcNameTokenEnd "\""

#define kObjcArrayTokenStart "["
#define kObjcArrayTokenEnd "]"

#define kObjcStructTokenStart "{"
#define kObjcStructTokenEnd "}"

#define kObjcStructDefinitionToken "="

struct loader_objc_lexer_token {
	char *type;
	char *typeName;
	char *formatter;
	size_t typeSize;
	enum LoaderObjcLexerTokenType typeClass;
	struct loader_objc_lexer_token *children;
	uint32_t childrenCount;
	uint32_t pointerCount;
	uint32_t arrayCount;
} ATR_PACK loader_objc_lexer_token;

struct loader_objc_lexer_type {
	struct loader_objc_lexer_token *token;
	uint32_t tokenCount;
} ATR_PACK loader_objc_lexer_type;

struct loader_objc_lexer_type *SDMSTObjcDecodeTypeWithLength(char *type, uint64_t decodeLength);
struct loader_objc_lexer_type *SDMSTObjcDecodeType(char *type);
CoreRange SDMSTObjcGetTokenRangeFromOffset(char *type, uint64_t offset, char *token);
char *SDMSTObjcPointersForToken(struct loader_objc_lexer_token *token);
uint64_t SDMSTObjcDecodeSizeOfType(struct loader_objc_lexer_token *token);

void loader_objc_lexer_type_release(struct loader_objc_lexer_type *decode);
void loader_objc_lexer_token_release(struct loader_objc_lexer_token *token);

void loader_objc_lexer_token_release(struct loader_objc_lexer_token *token)
{
	if (token != NULL) {
		token->type = NULL;

		if (token->typeName != NULL) {
			free(token->typeName);
		}
		token->typeName = NULL;

		token->formatter = NULL;

		token->typeSize = 0;

		token->typeClass = 0; // this will show up as ObjcCharEncoding

		if (token->childrenCount && token->children) {
			for (uint32_t child_index = 0; child_index < token->childrenCount; child_index++) {
				struct loader_objc_lexer_token *child = &(token->children[child_index]);
				loader_objc_lexer_token_release(child);
			}
			free(token->children);
			token->children = NULL;
			token->childrenCount = 0;
		}

		token->pointerCount = 0;

		token->arrayCount = 0;
	}
}

void loader_objc_lexer_type_release(struct loader_objc_lexer_type *decode)
{
	if (decode != NULL) {
		if (decode->tokenCount && decode->token != NULL) {
			for (uint32_t token_index = 0; token_index < decode->tokenCount; token_index++) {
				struct loader_objc_lexer_token *token = &(decode->token[token_index]);
				loader_objc_lexer_token_release(token);
			}
			free(decode->token);
			decode->token = NULL;
			decode->tokenCount = 0;
		}
		free(decode);
		decode = NULL;
	}
}

static size_t ObjcTypeSizes[kObjcTypeEncodingCount] = {
	sizeof(char),
	sizeof(int),
	sizeof(short),
	sizeof(long),
	sizeof(long long),
	sizeof(unsigned char),
	sizeof(unsigned int),
	sizeof(unsigned short),
	sizeof(unsigned long),
	sizeof(unsigned long long),
	sizeof(float),
	sizeof(double),
	sizeof(signed char),
	sizeof(void),
	sizeof(char *),
	sizeof(id),
	sizeof(Class),
	sizeof(SEL),
	sizeof(char),
	sizeof(Pointer),
	sizeof(Pointer)};

#define kObjcContainerTypeEncodingCount 1

static char *ObjcContainerTypeEncodingNames[kObjcContainerTypeEncodingCount] = {
	"struct"};

#define kObjcStackSizeCount 10

static char *ObjcStackSize[kObjcStackSizeCount] = {
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9"};

CoreRange SDMSTObjcStackSize(char *type, uint64_t offset, uint64_t *stackSize);
CoreRange SDMSTObjcGetRangeFromTokens(char *startToken, char *endToken, char *type, uint64_t offset);
CoreRange SDMSTObjcGetStructContentsRange(char *type, uint64_t offset);
CoreRange SDMSTObjcGetArrayContentsRange(char *type, uint64_t offset);
CoreRange SDMSTObjcGetStructNameRange(char *contents, uint64_t offset);
struct loader_objc_lexer_type *SDMSTMemberCountOfStructContents(char *structContents, CoreRange nameRange);
uint32_t SDMSTParseToken(struct loader_objc_lexer_type *decode, char *type, uint64_t offset);

CoreRange SDMSTObjcStackSize(char *type, uint64_t offset, uint64_t *stackSize)
{
	uint64_t counter = 0;
	bool findStackSize = true;
	while (findStackSize) {
		findStackSize = false;
		for (uint32_t i = 0; i < kObjcStackSizeCount; i++) {
			if (strncmp(&(type[offset + counter]), ObjcStackSize[i], sizeof(char)) == 0) {
				counter++;
				findStackSize = true;
				break;
			}
		}
	}
	CoreRange stackRange = CoreRangeCreate((uintptr_t)offset, counter);
	char *stack = calloc((uint32_t)stackRange.length + 1, sizeof(char));
	memcpy(stack, &(type[offset]), (uint32_t)stackRange.length);
	*stackSize = (uint64_t)atoi(stack);
	free(stack);
	return stackRange;
}

char *SDMSTObjcPointersForToken(struct loader_objc_lexer_token *token)
{
	char *pointers = calloc(1, sizeof(char) * (token->pointerCount + 1));
	if (token->pointerCount) {
		for (uint32_t i = 0; i < token->pointerCount; i++) {
			strcat(pointers, "*");
		}
	}
	return pointers;
}

CoreRange SDMSTObjcGetTokenRangeFromOffset(char *type, uint64_t offset, char *token)
{
	uint64_t counter = 0;
	while ((strncmp(&(type[offset + counter]), token, strlen(token)) != 0) && offset + counter < strlen(type)) {
		counter++;
	}
	return CoreRangeCreate((uintptr_t)offset, counter);
}

CoreRange SDMSTObjcGetRangeFromTokens(char *startToken, char *endToken, char *type, uint64_t offset)
{
	uint64_t stack = 1;
	uint64_t counter = 0;
	while (stack != 0) {
		if (strncmp(&(type[offset + counter]), startToken, sizeof(char)) == 0) {
			stack++;
		}
		if (strncmp(&(type[offset + counter]), endToken, sizeof(char)) == 0) {
			stack--;
		}
		counter++;
	}
	counter--;
	return CoreRangeCreate((uintptr_t)offset, counter);
}

CoreRange SDMSTObjcGetStructContentsRange(char *type, uint64_t offset)
{
	return SDMSTObjcGetRangeFromTokens(kObjcStructTokenStart, kObjcStructTokenEnd, type, offset);
}

CoreRange SDMSTObjcGetArrayContentsRange(char *type, uint64_t offset)
{
	return SDMSTObjcGetRangeFromTokens(kObjcArrayTokenStart, kObjcArrayTokenEnd, type, offset);
}

CoreRange SDMSTObjcGetStructNameRange(char *contents, uint64_t offset)
{
	return SDMSTObjcGetTokenRangeFromOffset(contents, offset, kObjcStructDefinitionToken);
}

struct loader_objc_lexer_type *SDMSTMemberCountOfStructContents(char *structContents, CoreRange nameRange)
{
	return SDMSTObjcDecodeTypeWithLength(structContents, nameRange.length);
}

uint32_t SDMSTParseToken(struct loader_objc_lexer_type *decode, char *type, uint64_t offset)
{
	uint32_t parsedLength = 1;
	uint32_t index = k32BitMask;
	for (uint32_t i = 0; i < kObjcTypeEncodingCount; i++) {
		if (strncmp(&(type[offset]), ObjcTypeEncoding[i], sizeof(char)) == 0) {
			index = i;
			break;
		}
	}
	if (index != k32BitMask && index < kObjcTypeEncodingCount) {
		decode->token[decode->tokenCount].typeClass = index;
		decode->token[decode->tokenCount].type = ObjcTypeEncodingNames[index];
		decode->token[decode->tokenCount].formatter = ObjcTypeFormatter[index];
		decode->token[decode->tokenCount].typeSize = ObjcTypeSizes[index];
		//if (decode->token[decode->tokenCount].typeName == 0) {
		decode->token[decode->tokenCount].typeName = NULL;
		//}
		switch (decode->token[decode->tokenCount].typeClass) {
			case ObjcCharEncoding:
			case ObjcIntEncoding:
			case ObjcShortEncoding:
			case ObjcLongEncoding:
			case ObjcLLongEncoding:
			case ObjcUCharEncoding:
			case ObjcUIntEncoding:
			case ObjcUShortEncoding:
			case ObjcULongEncoding:
			case ObjcULLongEncoding:
			case ObjcFloatEncoding:
			case ObjcDoubleEncoding:
			case ObjcBoolEncoding:
			case ObjcVoidEncoding:
			case ObjcStringEncoding: {
				decode->tokenCount++;
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				memset(&(decode->token[decode->tokenCount]), 0, sizeof(struct loader_objc_lexer_token));
				break;
			};
			case ObjcIdEncoding: {
				uint64_t next = offset + 1;
				if (strncmp(&(type[next]), kObjcNameTokenStart, sizeof(char)) == 0) {
					CoreRange nameRange = SDMSTObjcGetTokenRangeFromOffset(type, next + 1, kObjcNameTokenEnd);
					char *name = calloc(1, sizeof(char) * (3 + (uint32_t)nameRange.length));
					char *objectProtocolTest = &(type[nameRange.offset]);
					if (strncmp(objectProtocolTest, "<", 1) == 0 && strncmp(objectProtocolTest + (uint32_t)(nameRange.length - 1), ">", 1) == 0) {
						sprintf(&(name[0]), "id");
						memcpy(&(name[2]), &(type[nameRange.offset]), sizeof(char) * nameRange.length);
					}
					else {
						memcpy(name, &(type[nameRange.offset]), sizeof(char) * nameRange.length);
						sprintf(name, "%s*", name);
					}
					decode->token[decode->tokenCount].typeName = name;
					parsedLength += nameRange.length + 2;
				}
				if (strncmp(&(type[next]), kObjcUnknownEncoding, sizeof(char)) == 0) {
					// this is a block, the encoding is "@?"
					parsedLength += 1;
				}
				decode->tokenCount++;
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				memset(&(decode->token[decode->tokenCount]), 0, sizeof(struct loader_objc_lexer_token));
				break;
			};
			case ObjcClassEncoding:
			case ObjcSelEncoding:
			case ObjcBitEncoding: {
				decode->tokenCount++;
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				memset(&(decode->token[decode->tokenCount]), 0, sizeof(struct loader_objc_lexer_token));
				break;
			};
			case ObjcPointerEncoding: {
				decode->token[decode->tokenCount].pointerCount++;
				break;
			};
			case ObjcUnknownEncoding: {
				decode->token[decode->tokenCount].typeName = NULL;
				decode->tokenCount++;
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				memset(&(decode->token[decode->tokenCount]), 0, sizeof(struct loader_objc_lexer_token));
				break;
			};
			default: {
				break;
			};
		}
	}
	else {
		uint64_t stackSize;
		CoreRange stackRange = SDMSTObjcStackSize(type, offset, &stackSize);
		if (stackRange.length) {
			parsedLength = (uint32_t)stackRange.length;
		}
		else {
			if (strncmp(&(type[offset]), kObjcNameTokenStart, sizeof(char)) == 0) {
				CoreRange nameRange = SDMSTObjcGetTokenRangeFromOffset(type, offset + 1, kObjcNameTokenEnd);
				char *name = calloc(1, sizeof(char) * ((uint32_t)nameRange.length + 256));
				memcpy(name, &(type[nameRange.offset]), sizeof(char) * nameRange.length);
				decode->token[decode->tokenCount].typeName = name;
				parsedLength += (uint32_t)nameRange.length + 1;
			}
			if (strncmp(&(type[offset]), kObjcPointerEncoding, sizeof(char)) == 0) {
				decode->token[decode->tokenCount].pointerCount++;
			}
			if (strncmp(&(type[offset]), kObjcUnknownEncoding, sizeof(char)) == 0) {
				decode->token[decode->tokenCount].typeName = NULL;
			}
			if (strncmp(&(type[offset]), kObjcStructTokenStart, sizeof(char)) == 0) {
				uint64_t next = offset + 1;
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				decode->token[decode->tokenCount].typeClass = ObjcStructEncoding;
				decode->token[decode->tokenCount].type = ObjcContainerTypeEncodingNames[0];
				CoreRange contentsRange = SDMSTObjcGetStructContentsRange(type, next);
				char *contents = calloc(1, sizeof(char) * ((uint32_t)contentsRange.length + 256));
				memcpy(contents, &(type[next]), contentsRange.length);
				CoreRange nameRange = SDMSTObjcGetStructNameRange(contents, 0);
				char *name = calloc(1, sizeof(char) * ((uint32_t)nameRange.length + 256));
				memcpy(name, &(contents[nameRange.offset]), sizeof(char) * nameRange.length);
				decode->token[decode->tokenCount].typeName = name;

				char *structContentString = &(contents[nameRange.offset + nameRange.length]) + sizeof(char);
				CoreRange contentRange = CoreRangeCreate(0, strlen(structContentString));
				struct loader_objc_lexer_type *structContents = SDMSTMemberCountOfStructContents(structContentString, contentRange);
				decode->token[decode->tokenCount].childrenCount = structContents->tokenCount;
				decode->token[decode->tokenCount].children = calloc(structContents->tokenCount, sizeof(struct loader_objc_lexer_token));
				for (uint32_t i = 0; i < structContents->tokenCount; i++) {
					struct loader_objc_lexer_token *child = &(decode->token[decode->tokenCount].children[i]);
					struct loader_objc_lexer_token *structMember = &(structContents->token[i]);
					memcpy(child, structMember, sizeof(struct loader_objc_lexer_token));
				}
				parsedLength = (uint32_t)contentsRange.length + 1;
				free(structContents);

				decode->token[decode->tokenCount].typeSize = SDMSTObjcDecodeSizeOfType(&(decode->token[decode->tokenCount]));

				decode->tokenCount++;
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				memset(&(decode->token[decode->tokenCount]), 0, sizeof(struct loader_objc_lexer_token));
			}
			if (strncmp(&(type[offset]), kObjcArrayTokenStart, sizeof(char)) == 0) {
				uint64_t next = offset + 1;
				uint64_t nextStackSize;
				CoreRange nextStackRange = SDMSTObjcStackSize(type, next, &nextStackSize);
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				decode->token[decode->tokenCount].typeClass = ObjcArrayEncoding;
				decode->token[decode->tokenCount].arrayCount = (uint32_t)nextStackSize;
				next += nextStackRange.length;
				CoreRange arrayTypeRange = SDMSTObjcGetArrayContentsRange(type, next);
				char *arrayTypeString = calloc(1, sizeof(char) * (uint32_t)(arrayTypeRange.length + 1));
				memcpy(arrayTypeString, &(type[arrayTypeRange.offset]), arrayTypeRange.length);
				struct loader_objc_lexer_type *arrayType = SDMSTObjcDecodeType(arrayTypeString);
				char *typeAssignment = ObjcTypeEncodingNames[ObjcUnknownEncoding];
				if (arrayType->token[arrayType->tokenCount - 1].type) {
					typeAssignment = arrayType->token[arrayType->tokenCount - 1].type;
				}
				uint32_t typeLength = (uint32_t)strlen(typeAssignment);

				decode->token[decode->tokenCount].type = calloc(1, sizeof(char) * (typeLength + 1));
				memcpy(decode->token[decode->tokenCount].type, typeAssignment, typeLength);

				decode->token[decode->tokenCount].childrenCount = 1;
				decode->token[decode->tokenCount].children = calloc(1, sizeof(struct loader_objc_lexer_token));
				memcpy(decode->token[decode->tokenCount].children, &(arrayType->token[0]), sizeof(struct loader_objc_lexer_token));

				uint32_t newArrayLength = (uint32_t)(typeLength + 2 + (uint32_t)GetDigitsOfNumber(nextStackSize));
				char *name = calloc(1, sizeof(char) * (newArrayLength));
				memcpy(name, decode->token[decode->tokenCount].type, newArrayLength);
				sprintf(&(name[strlen(typeAssignment)]), "[%lld]", nextStackSize);
				decode->token[decode->tokenCount].typeName = name;
				parsedLength += arrayTypeRange.length + nextStackRange.length;
				free(arrayType);
				free(arrayTypeString);

				decode->token[decode->tokenCount].typeSize = ObjcTypeSizes[decode->token[decode->tokenCount].typeClass] * decode->token[decode->tokenCount].arrayCount;

				decode->tokenCount++;
				decode->token = realloc(decode->token, sizeof(struct loader_objc_lexer_token) * (decode->tokenCount + 1));
				memset(&(decode->token[decode->tokenCount]), 0, sizeof(struct loader_objc_lexer_token));
			}
		}
	}
	return parsedLength;
}

struct loader_objc_lexer_type *SDMSTObjcDecodeTypeWithLength(char *type, uint64_t decodeLength)
{
	struct loader_objc_lexer_type *decode = calloc(1, sizeof(struct loader_objc_lexer_type));
	decode->token = (struct loader_objc_lexer_token *)calloc(1, sizeof(struct loader_objc_lexer_token));
	uint64_t length = decodeLength;
	if (length) {
		uint64_t offset = 0;
		while (offset < length) {
			uint32_t parsedLength = SDMSTParseToken(decode, type, offset);
			offset = offset + parsedLength;
		}
	}
	return decode;
}

struct loader_objc_lexer_type *SDMSTObjcDecodeType(char *type)
{
	return SDMSTObjcDecodeTypeWithLength(type, strlen(type));
}

uint64_t SDMSTObjcDecodeSizeOfType(struct loader_objc_lexer_token *token)
{
	uint64_t size = 0;
	if (token) {
		if (token->childrenCount) {
			if (token->typeClass == ObjcStructEncoding) {
				for (uint32_t i = 0; i < token->childrenCount; i++) {
					uint64_t temp = SDMSTObjcDecodeSizeOfType(&(token->children[i]));
					size += temp;
				}
			}
			if (token->typeClass == ObjcArrayEncoding) {
				size += ObjcTypeSizes[token->children[0].typeClass] * token->arrayCount;
			}
		}
		else {
			if (token->pointerCount) {
				size += sizeof(Pointer);
			}
			else {
				size += ObjcTypeSizes[token->typeClass];
			}
		}
	}
	return size;
}

NSString *SDMSTObjcCreateFormatter(struct loader_objc_lexer_token *token, uintptr_t *ivar_pointer, uint64_t pointer_offset)
{
	NSMutableString *formattedType = [[[NSMutableString alloc] init] autorelease];

	if (token->formatter != nil) {
		uintptr_t *pointer_address = (uintptr_t *)PtrAdd(ivar_pointer, pointer_offset);
		NSString *formatterString = [NSString stringWithFormat:@"%s", token->formatter];
		switch (token->typeClass) {
			case ObjcCharEncoding: {
				char value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcIntEncoding: {
				int value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcShortEncoding: {
				short value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcLongEncoding: {
				long value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcLLongEncoding: {
				long long value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcUCharEncoding: {
				unsigned char value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcUIntEncoding: {
				unsigned int value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcUShortEncoding: {
				unsigned short value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcULongEncoding: {
				unsigned long value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcULLongEncoding: {
				unsigned long long value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcFloatEncoding: {
				float value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcDoubleEncoding: {
				double value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcBoolEncoding: {
				char value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcVoidEncoding: {
				void *value = 0;
				if (token->pointerCount) {
					memcpy(&value, pointer_address, token->typeSize + sizeof(void *));
				}
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcStringEncoding: {
				char *value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcIdEncoding: {
				id value = (id)*pointer_address;
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcClassEncoding: {
				Class value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcSelEncoding: {
				SEL value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcBitEncoding: {
				char value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcPointerEncoding: {
				Pointer value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcUnknownEncoding: {
				Pointer value = 0;
				memcpy(&value, pointer_address, token->typeSize);
				[formattedType appendFormat:formatterString, value];
				break;
			}
			case ObjcStructEncoding: {
				if (token->pointerCount) {
					Pointer value = 0;
					memcpy(&value, pointer_address, token->typeSize);
					[formattedType appendFormat:formatterString, value];
				}
				break;
			}
			default: {
				break;
			}
		}
	}
	else {

		for (uint32_t index = 0; index < token->childrenCount; index++) {
			struct loader_objc_lexer_token *child = &(token->children[index]);

			NSString *formatterString = SDMSTObjcCreateFormatter(child, ivar_pointer, pointer_offset);

			uint64_t size = 0;

			if (child->typeClass == ObjcStructEncoding) {
				NSString *structFormat = @"struct";
				if (child->typeName != nil) {
					structFormat = [structFormat stringByAppendingString:@" %s"];
				}

				structFormat = [structFormat stringByAppendingString:@"%s "];

				if (child->pointerCount) {
					structFormat = [structFormat stringByAppendingString:@"= %@"];
				}
				else {
					structFormat = [structFormat stringByAppendingString:@"{%@}"];
				}

				char *pointers = SDMSTObjcPointersForToken(child);
				if (child->typeName != nil) {
					structFormat = [NSString stringWithFormat:structFormat, child->typeName, pointers, formatterString];
				}
				else {
					structFormat = [NSString stringWithFormat:structFormat, pointers, formatterString];
				}
				[formattedType appendFormat:@"%@", structFormat];
				free(pointers);
				size = SDMSTObjcDecodeSizeOfType(child);
			}
			else if (child->typeClass == ObjcArrayEncoding) {
				uint64_t array_offset = pointer_offset;
				uint64_t element_size = SDMSTObjcDecodeSizeOfType(&(child->children[0]));

				NSMutableString *formattedContents = [[[NSMutableString alloc] init] autorelease];

				for (uint32_t array_index = 0; array_index < child->arrayCount; array_index++) {

					formatterString = SDMSTObjcCreateFormatter(child, ivar_pointer, array_offset);

					[formattedContents appendString:formatterString];

					if (array_index + 1 < child->arrayCount) {
						[formattedContents appendFormat:@", "];
					}

					array_offset += element_size;
				}

				[formattedType appendFormat:@"%@", [NSString stringWithFormat:@"%s[%i] = {%@}", child->type, child->arrayCount, formattedContents]];
				size = element_size * child->arrayCount;
			}
			else {
				char *pointers = SDMSTObjcPointersForToken(child);
				[formattedType appendFormat:@"(%s%s) = %@", child->type, pointers, formatterString];
				free(pointers);
				size = SDMSTObjcDecodeSizeOfType(child);
			}

			if (index + 1 < token->childrenCount) {
				[formattedType appendFormat:@", "];
			}

			// finish by advancing the type size
			pointer_offset += size;
		}
	}

	return [formattedType copy];
}

@implementation BaseDataModelObject

- (NSString *)debugDescription
{
	Class selfClass = [self class];

	NSMutableString *debugDescription = [[[NSMutableString alloc] init] autorelease];
	[debugDescription appendFormat:@"<%@: %p>", NSStringFromClass(selfClass), self];

	unsigned int property_count = 0;
	objc_property_t *properties = class_copyPropertyList(selfClass, &property_count);

	for (unsigned int property_index = 0; property_index < property_count; property_index++) {
		objc_property_t property = properties[property_index];

		char *property_type = property_copyAttributeValue(property, "T"); // get property type
		const char *property_name = property_getName(property);

		if (property_type != nil) {
			char *ivar_name = property_copyAttributeValue(property, "V"); // get the property ivar name
			uintptr_t *ivar_pointer = nil;
			Ivar property_ivar = object_getInstanceVariable(self, ivar_name, (void **)&ivar_pointer);
			ivar_pointer = (uintptr_t *)PtrAdd((__bridge void *)self, ivar_getOffset(property_ivar));

			uint64_t pointer_offset = 0;
			NSString *typeEncodingFormatter = @"";

			struct loader_objc_lexer_type *decode = SDMSTObjcDecodeType(property_type);
			for (uint32_t type_index = 0; type_index < decode->tokenCount; type_index++) {
				struct loader_objc_lexer_token *token = &(decode->token[type_index]);

				// attempting to guess at the type based on property name
				if ((token->typeClass == ObjcCharEncoding) && (strncmp("is", property_name, sizeof(char[2])) == 0 || strncmp("has", property_name, sizeof(char[3])) == 0)) {
					token->typeClass = ObjcBoolEncoding;
					token->formatter = ObjcTypeFormatter[token->typeClass];
				}

				NSString *formatterString = @"";
				if (token->typeClass == ObjcStructEncoding) {

					NSUInteger value_size = 0;
					NSUInteger alignment = 0;
					NSGetSizeAndAlignment(property_type, &value_size, &alignment);
					if (token->typeSize == value_size) {
						// If the size of the struct matches the exact length of the packed size, we can unpack all the members safely.
						formatterString = SDMSTObjcCreateFormatter(token, ivar_pointer, pointer_offset);
					}
					else {
						// If the struct isn't aligned then use NSValue to display
						formatterString = [NSString stringWithFormat:@"%@", [NSValue valueWithBytes:ivar_pointer objCType:property_type]];
					}
				}
				else {
					formatterString = SDMSTObjcCreateFormatter(token, ivar_pointer, pointer_offset);
				}

				if (token->typeClass == ObjcStructEncoding) {
					NSString *structFormat = @"struct";
					// getting the struct name
					if (token->typeName != nil) {
						structFormat = [structFormat stringByAppendingString:@" %s"];
					}

					// getting pointers
					structFormat = [structFormat stringByAppendingString:@"%s "];

					// change the formatting if the struct is a pointer or not
					if (token->pointerCount) {
						structFormat = [structFormat stringByAppendingString:@"= %@"];
					}
					else {
						structFormat = [structFormat stringByAppendingString:@"{%@}"];
					}

					// now create the file formatting name
					char *pointers = SDMSTObjcPointersForToken(token);
					if (token->typeName != nil) {
						typeEncodingFormatter = [NSString stringWithFormat:structFormat, token->typeName, pointers, formatterString];
					}
					else {
						typeEncodingFormatter = [NSString stringWithFormat:structFormat, pointers, formatterString];
					}
					free(pointers);
				}
				else {
					typeEncodingFormatter = formatterString;
				}

				// finish by advancing the type size
				pointer_offset += token->typeSize;
			}
			loader_objc_lexer_type_release(decode);
			decode = NULL;

			[debugDescription appendFormat:@"\n%s: %@", property_name, typeEncodingFormatter];
			
			if (ivar_name != nil) {
				free(ivar_name);
			}

			if (property_type != nil) {
				free(property_type);
			}
		}
	}

	if (properties != nil) {
		free(properties);
	}

	[debugDescription appendFormat:@"\n"];

	return [[debugDescription copy] autorelease]; // immutable copy
}

@end

#endif
