declare global {
    interface DocumentEventMap {
        'theme-change': CustomEvent<{ theme: 'light' | 'dark' }>;
    }
}

export function getTheme(): 'light' | 'dark' {
    const theme = localStorage?.getItem('theme');

    if (theme === 'light' || theme === 'dark') {
        return theme;
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light';
}

export function setTheme(theme: 'light' | 'dark') {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage?.setItem('theme', theme);

    // send theme change event
    const event = new CustomEvent('theme-change', {
        bubbles: true,
        detail: { theme },
    });
    document.dispatchEvent(event);
}

document.addEventListener('DOMContentLoaded', () => {
    setTheme(getTheme());
});
