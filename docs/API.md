# API

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**action** | [**ApiAction**](ApiAction.md) |  | 
**audio** | **String** | input audio as base64 — data URI (web) or raw base64 (android/ios), empty if unused; type detected server-side | 
**balance** | **Int64** |  | 
**credit** | **Int64** |  | 
**file** | **String** | filename of result to retrieve | 
**id** | **UUID** | uuid v7 | 
**image** | **String** | input image as base64 — data URI (web) or raw base64 (android/ios), empty if unused; type detected server-side | 
**messages** | [ApiChatMessage] | default value is non-empty array | 
**model** | [**ApiAiModel**](ApiAiModel.md) |  | 
**pay** | [**ApiPay**](ApiPay.md) |  | 
**prompt** | **String** |  | 
**requestId** | **String** | transient, managed by server | 
**status** | [**ApiStatus**](ApiStatus.md) |  | 
**userId** | **String** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


