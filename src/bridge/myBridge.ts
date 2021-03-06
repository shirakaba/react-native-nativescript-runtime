global.isAndroid = !!global.android;
global.isIOS = !global.android;
global.native = global;

const bridgeRequestName = "NativeScriptBridgeRequest";
const bridgeResponseName = "NativeScriptBridgeResponse";

/**
 * A callback by which to deinitialise the bridge.
 * 
 */
let unsubscribe: null | (() => void) = null;

interface BridgeResponseIosReject {
    "id": string;
    "responseType": "reject";
    "rejectArgs": [string, string, NSError];
}

interface BridgeResponseIosResolve {
    "id": string;
    "responseType": "resolve";
    "resolveArg": any;
}

type BridgeMessageHandlerIos = (id: string, payload: any|undefined, callback: (resolution: BridgeResponseIosResolve | BridgeResponseIosReject) => void) => void;
// type BridgeMessageHandlerAndroid = (id: string, payload: any) => any;
type BridgeMessageHandler = BridgeMessageHandlerIos; // | BridgeMessageHandlerAndroid;

interface BridgeController {
    [messageName: string]: BridgeMessageHandler | undefined;
}

/**
 * A registry of response handlers to given message names.
 */
const controller: BridgeController = {};

export function addHandlerToController(messageName: string, handler: BridgeMessageHandler): void {
    controller[messageName] = handler;
}

const bridgeErrorDomain = "org.nativescript.rnbridge";
const version: number = 4;

/**
 * As React Native has always been limited to JSON communication, we can expect to be dealing with JSON-serialisable values.
 * @see https://twitter.com/sjchmiela/status/1330499930994171904?s=20
 * 
 * ... with the exception of some methods that resolve nil, which we should translate as undefined.
 * We'd only get nil as the resolution itself, rather than a nested property in the NSDictionary, though.
 * @see https://twitter.com/sjchmiela/status/1330500505706127363?s=20
 */
 function marshalIos(nativeValue: unknown): any {
    if(nativeValue instanceof NSDictionary){
      const obj: any = {};
      //@ts-ignore
      nativeValue.enumerateKeysAndObjectsUsingBlock((key: string, value: any, stop: interop.Reference<boolean>) => {
        obj[key] = marshalIos(value);
      });
      return obj;
    } else if (nativeValue instanceof NSArray){
      const arr: any[] = [];
      //@ts-ignore
      nativeValue.enumerateObjectsUsingBlock((value: any, index: number, stop: interop.Reference<boolean>) => {
        arr[index] = marshalIos(value);
      });
      return arr;
    } else {
      /**
       * NSDate, NSString, NSNumber, and NSNull should all be automatically marshalled as Date, string, number, and null.
       * @see https://docs.nativescript.org/core-concepts/ios-runtime/marshalling-overview#primitive-exceptions
       * 
       * NULL, Nil, and nil are all implicitly converted to null.
       * @see https://docs.nativescript.org/core-concepts/ios-runtime/marshalling-overview#null-values
       */
      return nativeValue as Date|string|number|null;
    }
  }

/**
 * Just as we use the addHandlerToController() API in this plugin, you can import this API into any TS/JS file under your app's
 * nativescript/src folder to add your own NativeScript method.
 * 
 * TODO: Move this into nativescript/src
 * 
 * Call this from React Native using:
 * @example 
 * import { NativeModules } from 'react-native';
 * const sum = await NativeModules.NativescriptRuntime.postMessage('addNumbers', { a: 1, b: 2 });
 */
addHandlerToController(
    "addNumbers",
    (id: string, payload: { a: number, b: number }, callback: (resolution: BridgeResponseIosResolve | BridgeResponseIosReject) => void) => {
        console.log(`[NativeScriptBridgeRequest] v${version} Running block for "addNumbers":`, { payload, id });
        if(typeof payload !== "object" || typeof payload.a !== "number" || typeof payload.b !== "number"){
            console.log(`[NativeScriptBridgeRequest] v${version} Will reject "addNumbers"...`);
            const errorCode = -1;
            const errorMessage = "Invalid arguments";
            const nsError = NSError.alloc().initWithDomainCodeUserInfo(
                bridgeErrorDomain,
                errorCode,
                NSDictionary.dictionaryWithObjectsForKeys(
                    [errorMessage],
                    [NSLocalizedDescriptionKey]
                ),
            );

            return callback({
                id,
                responseType: "reject",
                rejectArgs: [errorCode.toString(), errorMessage, nsError],
            });
        }

        const resolution = {
            id,
            responseType: "resolve" as const,
            resolveArg: payload.a + payload.b,
        };

        console.log(`[NativeScriptBridgeRequest] v${version} Will resolve "addNumbers" with resolution`, resolution);

        return callback(resolution);
    },
);

/**
 * Initialises the React Native -> NativeScript bridge, allowing NativeScript to subscribe to messages
 * sent from React Native.
 * @returns A callback by which to deinitialise the bridge (i.e. stop listening for bridge messages).
 *          Or null, if the bridge has already been initialised.
 */
export function initBridge(): null | (() => void) {
    if(unsubscribe){
        return unsubscribe;
    }
    
    if(global.isIOS){
        /**
         * @see https://developer.apple.com/documentation/foundation/nsnotificationcenter/1415360-addobserver
         */
        const observer = NSNotificationCenter.defaultCenter.addObserverForNameObjectQueueUsingBlock(
            bridgeRequestName,
            null,
            NSOperationQueue.mainQueue,
            (notification: NSNotification) => {
                const {
                    object: source,
                    userInfo,
                } = notification;
                console.log(`[NativeScriptBridgeRequest] v${version} from ${source} with userInfo`, userInfo);

                const name: string = userInfo.valueForKey("name");
                const payload: any = userInfo.valueForKey("payload");
                const id: string = userInfo.valueForKey("id");

                console.log(`[NativeScriptBridgeRequest] v${version} notification parsed as dictionary:`, { name, payload, id });

                function postNotification(responseUserInfo: BridgeResponseIosResolve | BridgeResponseIosReject): void {
                    NSNotificationCenter.defaultCenter.postNotificationNameObjectUserInfo(
                        bridgeResponseName,
                        null,
                        NSDictionary.dictionaryWithObjectsForKeys(
                            [
                                responseUserInfo.id,
                                responseUserInfo.responseType,
                                responseUserInfo.responseType === "reject" ? responseUserInfo.rejectArgs : responseUserInfo.resolveArg,
                            ],
                            [
                                "id",
                                "responseType",
                                responseUserInfo.responseType === "reject" ? "rejectArgs" : "resolveArg"
                            ]
                        )
                    );
    
                    console.log(`[NativeScriptBridgeRequest] v${version} posted :`, responseUserInfo);
                }

                let payloadJS: any;
                try {
                    payloadJS = marshalIos(payload);
                    console.log(`[NativeScriptBridgeRequest] v${version} payload marshalled:`, payloadJS);
                } catch(error){
                    console.log(`[NativeScriptBridgeRequest] v${version} Failed to marshal value for name "${name}"; rejecting...`);
                    const errorCode = -1;
                    const errorMessage = `Failed to marshal value for name "${name}"`;
                    const nsError = NSError.alloc().initWithDomainCodeUserInfo(
                        bridgeErrorDomain,
                        errorCode,
                        NSDictionary.dictionaryWithObjectsForKeys(
                            [errorMessage],
                            [NSLocalizedDescriptionKey]
                        ),
                    );

                    return postNotification({
                        id,
                        responseType: "reject",
                        rejectArgs: [errorCode.toString(), errorMessage, nsError],
                    });
                }

                const handler = controller[name];
                if(!handler){
                    console.log(`[NativeScriptBridgeRequest] v${version} Lacked handler for name "${name}"; rejecting...`);
                    const errorCode = -1;
                    const errorMessage = `No handler for bridge message named "${name}"`;
                    const nsError = NSError.alloc().initWithDomainCodeUserInfo(
                        bridgeErrorDomain,
                        errorCode,
                        NSDictionary.dictionaryWithObjectsForKeys(
                            [errorMessage],
                            [NSLocalizedDescriptionKey]
                        ),
                    );

                    return postNotification({
                        id,
                        responseType: "reject",
                        rejectArgs: [errorCode.toString(), errorMessage, nsError],
                    });
                }

                console.log(`[NativeScriptBridgeRequest] v${version} Got handler for name "${name}"!`);
                try {
                    handler(
                        id,
                        payloadJS,
                        (resolution: BridgeResponseIosResolve | BridgeResponseIosReject) => {
                            console.log(`[NativeScriptBridgeRequest] v${version} Posting notification for handler named "${name}"...`);
                            postNotification(resolution);
                        }
                    );
                } catch(error){
                    console.error(`[NativeScriptBridgeRequest] v${version} Unexpected error in handler for "${name}"`, error);
                    const errorCode = -1;
                    const errorMessage = `Unexpected error in handler for "${name}": ${error.message}`;
                    const nsError = NSError.alloc().initWithDomainCodeUserInfo(
                        bridgeErrorDomain,
                        errorCode,
                        NSDictionary.dictionaryWithObjectsForKeys(
                            [errorMessage],
                            [NSLocalizedDescriptionKey]
                        ),
                    );
    
                    const rejection: BridgeResponseIosReject = {
                        id,
                        responseType: "reject" as const,
                        rejectArgs: [errorCode.toString(), errorMessage, nsError],
                    };
                    postNotification(rejection);
                }
            }
        );

        unsubscribe = () => {
            NSNotificationCenter.defaultCenter.removeObserver(observer);
        };
        return unsubscribe;
    }

    if(global.isAndroid){
        // TODO: implement.
        /**
         * For Android,
         * @see https://github.com/NativeScript/NativeScript/blob/dac36c68015512553689f6803d147da92f89cd93/packages/core/application/index.d.ts#L631-L636
         * @see http://developer.android.com/reference/android/content/Context.html#registerReceiver%28android.content.BroadcastReceiver,%20android.content.IntentFilter%29
         */
        throw new Error('Android bridge not yet implemented.');
    }

    throw new Error('Unimplemented platform. Only iOS and Android are supported.');
}