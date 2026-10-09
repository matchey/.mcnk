// Paste this file into Surfingkeys Advanced mode and save to apply it.
// Browser-level Alt+J/K switch next/previous tabs where content scripts cannot run.
// Configured separately: chrome://extensions/shortcuts, edge://extensions/shortcuts, Firefox about:addons.
api.map('J', 'R');
api.map('K', 'E');
api.map('H', 'S');
api.map('L', 'D');
api.map('<Ctrl-o>', 'B');
api.map('<Ctrl-i>', 'F');
api.map('gt', 'R');
api.map('gT', 'E');
api.map('<Ctrl-d>', 'd');
api.map('<Ctrl-u>', 'e');
api.map('<Ctrl-f>', 'P');
api.map('<Ctrl-b>', 'U');
api.map('u', 'X');
api.unmap('d');

// Numeric prefixes invoke custom callbacks synchronously; schedule only one action.
function oncePerKeypress(action) {
    let scheduled = false;
    return () => {
        if (scheduled) return;
        scheduled = true;
        queueMicrotask(() => {
            scheduled = false;
            action();
        });
    };
}

api.mapkey('dd', '#3Close current tab', oncePerKeypress(() => {
    api.Normal.feedkeys('x');
}), { repeatIgnore: true });

function clipboardURL(text) {
    const value = text.trim();
    if (!/^https?:\/\/[^/]/i.test(value) || /[\s\\]/.test(value)) {
        return null;
    }
    try {
        const url = new URL(value);
        return url.hostname ? value : null;
    } catch (error) {
        if (error instanceof TypeError) return null;
        throw error;
    }
}

let clipboardReadPending = false;
function openClipboardURL() {
    if (clipboardReadPending) {
        api.Front.showBanner('A clipboard read is still pending. Reload this page to retry.');
        return;
    }
    clipboardReadPending = true;
    let finished = false;
    const timeout = setTimeout(() => {
        finished = true;
        // Clipboard.read shares a callback; do not let a late reply reach a newer request.
        api.Front.showBanner('Clipboard read timed out. Reload this page to retry.');
    }, 3000);

    function finishRead(response) {
        clipboardReadPending = false;
        clearTimeout(timeout);
        if (finished) return;
        finished = true;
        if (!response || response.error || typeof response.data !== 'string') {
            api.Front.showBanner('Unable to read the clipboard.');
            return;
        }
        const url = clipboardURL(response.data);
        if (!url) {
            api.Front.showBanner('Clipboard must contain one complete HTTP(S) URL.');
            return;
        }
        api.RUNTIME('openLink', { url, tab: { tabbed: true, active: true } });
    }

    try {
        // Firefox's Clipboard.read does not forward readText() rejections.
        if (api.getBrowserName() === 'Firefox' && navigator.clipboard?.readText) {
            navigator.clipboard.readText().then(
                (data) => finishRead({ data }),
                () => finishRead({ error: true }),
            );
        } else {
            api.Clipboard.read(finishRead);
        }
    } catch (error) {
        finishRead({ error: true });
    }
}

api.mapkey('p', '#8Open clipboard URL in a new tab', oncePerKeypress(openClipboardURL),
    { repeatIgnore: true });

// Match only the exported HTTPS origins; the site toggle cannot override this.
settings.blocklistPattern = /^https:\/\/(?:sushida\.net|o24\.works)(?::443)?(?:\/|$)/i;

settings.theme = `
.sk_theme {
    font-family: Input Sans Condensed, Charcoal, sans-serif;
    font-size: 10pt;
    background: #24272e;
    color: #abb2bf;
}
.sk_theme tbody {
    color: #fff;
}
.sk_theme input {
    color: #d0d0d0;
}
.sk_theme .url {
    color: #61afef;
}
.sk_theme .annotation {
    color: #56b6c2;
}
.sk_theme .omnibar_highlight {
    color: #528bff;
}
.sk_theme .omnibar_timestamp {
    color: #e5c07b;
}
.sk_theme .omnibar_visitcount {
    color: #98c379;
}
.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
    background: #303030;
}
.sk_theme #sk_omnibarSearchResult ul li.focused {
    background: #3e4452;
}
#sk_status, #sk_find {
    font-size: 20pt;
}`;
