import Foundation

class ScriptletLibrary {
    
    static func getScriptletCode(for name: String) -> String? {
        switch name {
        case "json-prune":
            return jsonPruneScriptlet()
        case "set-constant":
            return setConstantScriptlet()
        case "abort-on-property-read":
            return abortOnPropertyReadScriptlet()
        case "abort-on-property-write":
            return abortOnPropertyWriteScriptlet()
        case "abort-current-inline-script":
            return abortCurrentInlineScriptScriptlet()
        case "addEventListener-defuser", "prevent-addEventListener":
            return preventAddEventListenerScriptlet()
        case "remove-attr":
            return removeAttributeScriptlet()
        case "set-attr":
            return setAttributeScriptlet()
        case "remove-class":
            return removeClassScriptlet()
        case "prevent-xhr":
            return preventXHRScriptlet()
        case "prevent-fetch":
            return preventFetchScriptlet()
        case "no-setTimeout-if":
            return noSetTimeoutIfScriptlet()
        case "no-setInterval-if":
            return noSetIntervalIfScriptlet()
        case "log":
            return logScriptlet()
        default:
            return nil
        }
    }
    
    private static func jsonPruneScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['json-prune'] = function(source, ...args) {
                const propsToRemove = args;
                const originalParse = JSON.parse;
                
                JSON.parse = new Proxy(originalParse, {
                    apply: function(target, thisArg, args) {
                        const obj = Reflect.apply(target, thisArg, args);
                        
                        if (obj && typeof obj === 'object') {
                            propsToRemove.forEach(prop => {
                                const props = prop.split('.');
                                let current = obj;
                                const lastProp = props.pop();
                                
                                for (const p of props) {
                                    if (!current[p]) break;
                                    current = current[p];
                                }
                                
                                if (current && lastProp) {
                                    delete current[lastProp];
                                }
                            });
                        }
                        
                        return obj;
                    }
                });
            };
        })();
        """
    }
    
    private static func setConstantScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['set-constant'] = function(source, property, value) {
                if (!property) return;
                
                const constantValue = (() => {
                    switch (value) {
                        case 'undefined': return undefined;
                        case 'null': return null;
                        case 'false': return false;
                        case 'true': return true;
                        case 'noopFunc': return function(){};
                        case 'trueFunc': return function(){ return true; };
                        case 'falseFunc': return function(){ return false; };
                        case '[]': return [];
                        case '{}': return {};
                        case '""': return "";
                        default:
                            if (!isNaN(value)) return Number(value);
                            return value;
                    }
                })();
                
                const props = property.split('.');
                const lastProp = props.pop();
                let obj = window;
                
                for (const prop of props) {
                    obj = obj[prop] = obj[prop] || {};
                }
                
                Object.defineProperty(obj, lastProp, {
                    value: constantValue,
                    configurable: false,
                    writable: false
                });
            };
        })();
        """
    }
    
    private static func abortOnPropertyReadScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['abort-on-property-read'] = function(source, property) {
                if (!property) return;
                
                const props = property.split('.');
                const lastProp = props.pop();
                let obj = window;
                
                for (const prop of props) {
                    obj = obj[prop];
                    if (!obj) return;
                }
                
                Object.defineProperty(obj, lastProp, {
                    get: function() {
                        throw new ReferenceError(`Property '${property}' not found`);
                    },
                    set: function() {}
                });
            };
        })();
        """
    }
    
    private static func abortOnPropertyWriteScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['abort-on-property-write'] = function(source, property) {
                if (!property) return;
                
                const props = property.split('.');
                const lastProp = props.pop();
                let obj = window;
                
                for (const prop of props) {
                    obj = obj[prop];
                    if (!obj) return;
                }
                
                Object.defineProperty(obj, lastProp, {
                    get: function() {
                        return undefined;
                    },
                    set: function() {
                        throw new ReferenceError(`Property '${property}' not found`);
                    }
                });
            };
        })();
        """
    }
    
    private static func abortCurrentInlineScriptScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['abort-current-inline-script'] = function(source, property, search) {
                if (!property) return;
                
                const searchRegexp = search ? new RegExp(search) : null;
                const props = property.split('.');
                let obj = window;
                
                for (let i = 0; i < props.length - 1; i++) {
                    obj = obj[props[i]];
                    if (!obj) return;
                }
                
                const prop = props[props.length - 1];
                let value = obj[prop];
                
                Object.defineProperty(obj, prop, {
                    get: function() {
                        const stack = new Error().stack || '';
                        const inline = stack.includes('at <anonymous>:1:1');
                        
                        if (inline && (!searchRegexp || searchRegexp.test(stack))) {
                            throw new ReferenceError(`Property '${property}' not found`);
                        }
                        
                        return value;
                    },
                    set: function(v) {
                        value = v;
                    }
                });
            };
        })();
        """
    }
    
    private static func preventAddEventListenerScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['prevent-addEventListener'] = function(source, eventType, handler) {
                const originalAddEventListener = EventTarget.prototype.addEventListener;
                
                EventTarget.prototype.addEventListener = function(type, listener, options) {
                    if ((!eventType || type === eventType) && 
                        (!handler || (listener && listener.toString().includes(handler)))) {
                        console.log(`[wBlock] Prevented addEventListener: ${type}`);
                        return;
                    }
                    
                    return originalAddEventListener.apply(this, arguments);
                };
            };
        })();
        """
    }
    
    private static func removeAttributeScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['remove-attr'] = function(source, attr, selector) {
                if (!attr) return;
                
                const removeAttributes = () => {
                    const elements = selector ? 
                        document.querySelectorAll(selector) : 
                        document.querySelectorAll(`[${attr}]`);
                        
                    elements.forEach(el => {
                        el.removeAttribute(attr);
                    });
                };
                
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', removeAttributes);
                } else {
                    removeAttributes();
                }
                
                // Watch for new elements
                const observer = new MutationObserver(removeAttributes);
                observer.observe(document.documentElement, {
                    childList: true,
                    subtree: true
                });
            };
        })();
        """
    }
    
    private static func setAttributeScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['set-attr'] = function(source, selector, attr, value) {
                if (!selector || !attr) return;
                
                const setAttributes = () => {
                    const elements = document.querySelectorAll(selector);
                    elements.forEach(el => {
                        el.setAttribute(attr, value || '');
                    });
                };
                
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', setAttributes);
                } else {
                    setAttributes();
                }
                
                // Watch for new elements
                const observer = new MutationObserver(setAttributes);
                observer.observe(document.documentElement, {
                    childList: true,
                    subtree: true
                });
            };
        })();
        """
    }
    
    private static func removeClassScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['remove-class'] = function(source, className, selector) {
                if (!className) return;
                
                const classes = className.split(/\\s+/);
                const removeClasses = () => {
                    const elements = selector ? 
                        document.querySelectorAll(selector) : 
                        document.querySelectorAll('*');
                        
                    elements.forEach(el => {
                        classes.forEach(cls => {
                            if (el.classList.contains(cls)) {
                                el.classList.remove(cls);
                            }
                        });
                    });
                };
                
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', removeClasses);
                } else {
                    removeClasses();
                }
                
                // Watch for new elements
                const observer = new MutationObserver(removeClasses);
                observer.observe(document.documentElement, {
                    childList: true,
                    subtree: true,
                    attributes: true,
                    attributeFilter: ['class']
                });
            };
        })();
        """
    }
    
    private static func preventXHRScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['prevent-xhr'] = function(source, pattern) {
                const xhrOpen = XMLHttpRequest.prototype.open;
                const patternRegexp = pattern ? new RegExp(pattern) : null;
                
                XMLHttpRequest.prototype.open = function(method, url) {
                    if (patternRegexp && patternRegexp.test(url)) {
                        console.log(`[wBlock] Blocked XHR: ${url}`);
                        throw new Error('XHR blocked');
                    }
                    
                    return xhrOpen.apply(this, arguments);
                };
            };
        })();
        """
    }
    
    private static func preventFetchScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['prevent-fetch'] = function(source, pattern) {
                const originalFetch = window.fetch;
                const patternRegexp = pattern ? new RegExp(pattern) : null;
                
                window.fetch = function(input, init) {
                    const url = typeof input === 'string' ? input : input.url;
                    
                    if (patternRegexp && patternRegexp.test(url)) {
                        console.log(`[wBlock] Blocked fetch: ${url}`);
                        return Promise.reject(new Error('Fetch blocked'));
                    }
                    
                    return originalFetch.apply(this, arguments);
                };
            };
        })();
        """
    }
    
    private static func noSetTimeoutIfScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['no-setTimeout-if'] = function(source, pattern, delay) {
                const originalSetTimeout = window.setTimeout;
                const patternRegexp = pattern ? new RegExp(pattern) : null;
                const delayMatch = delay ? parseInt(delay) : null;
                
                window.setTimeout = function(callback, timeout) {
                    const callbackStr = callback.toString();
                    
                    if (patternRegexp && patternRegexp.test(callbackStr)) {
                        if (!delayMatch || timeout === delayMatch) {
                            console.log(`[wBlock] Blocked setTimeout`);
                            return;
                        }
                    }
                    
                    return originalSetTimeout.apply(this, arguments);
                };
            };
        })();
        """
    }
    
    private static func noSetIntervalIfScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['no-setInterval-if'] = function(source, pattern, delay) {
                const originalSetInterval = window.setInterval;
                const patternRegexp = pattern ? new RegExp(pattern) : null;
                const delayMatch = delay ? parseInt(delay) : null;
                
                window.setInterval = function(callback, timeout) {
                    const callbackStr = callback.toString();
                    
                    if (patternRegexp && patternRegexp.test(callbackStr)) {
                        if (!delayMatch || timeout === delayMatch) {
                            console.log(`[wBlock] Blocked setInterval`);
                            return;
                        }
                    }
                    
                    return originalSetInterval.apply(this, arguments);
                };
            };
        })();
        """
    }
    
    private static func logScriptlet() -> String {
        return """
        (function() {
            'use strict';
            window.adguardScriptlets = window.adguardScriptlets || {};
            window.adguardScriptlets['log'] = function(source, text) {
                console.log(`[wBlock Log] ${text || 'log scriptlet executed'}`);
            };
        })();
        """
    }
}
