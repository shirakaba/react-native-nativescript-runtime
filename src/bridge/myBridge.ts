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
    const version: number = 4;
    
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
                console.log(`[NativeScriptBridgeRequest] v${version} from ${source}`, userInfo);

                const name: string = userInfo.valueForKey("name");
                const payload: any = userInfo.valueForKey("payload");
                const id: string = userInfo.valueForKey("id");

                console.log(`[NativeScriptBridgeRequest] v${version} notification parsed:`, { name, payload, id });

                // const resolve: (...args: any[]) => void = userInfo.valueForKey("resolve");
                // const reject: (...args: any[]) => void = userInfo.valueForKey("reject");
                
                // if(resolve){
                //     console.log('[NativeScriptBridgeRequest] resolving null, 123 with resolve handler:', resolve);
                //     // NativeScript seems to marshall this incorrectly, as it crashes with a TypeError here :(
                //     resolve(null, 123);
                // } else {
                //     console.log('[NativeScriptBridgeRequest] lacked resolve handler!');
                // }

                const responseUserInfo = NSDictionary.dictionaryWithObjectsForKeys(
                    [
                        id,
                        "resolve",
                        123,
                    ],
                    [
                        "id",
                        "responseType",
                        "resolveArg",
                    ]
                );

                NSNotificationCenter.defaultCenter.postNotificationNameObjectUserInfo(
                    bridgeResponseName,
                    null,
                    responseUserInfo
                );

                console.log(`[NativeScriptBridgeRequest] v${version} posted :`, responseUserInfo);
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