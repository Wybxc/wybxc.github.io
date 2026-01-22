#import "../../template.typ": *
#show: post.with(
  title: "Stop Using Theme Toggle Buttons",
  pubDate: datetime(year: 2026, month: 1, day: 22),
)

= Stop Using Theme Toggle Buttons

TL;DR: Just follow the `prefers-color-scheme` media query. A badly implemented theme toggle is worse than having none at all.

== The Dark Theme Saga

It's 2026. Over 99.5%#footnote[
  Obviously not a real stat. But hey, we always ignore that last 0.5%, don't we?
] of frontend developers have finally accepted that their websites need a dark theme. Mainly to save their users' eyes, especially after burning their own retinas while coding into the wee hours.

Thankfully, implementing dark mode isn't rocket science these days. Every modern component library comes with dark theme support baked in#footnote[
  I mean, if it doesn't support dark mode, it's not "modern".
]. Take #link("https://daisyui.com")[DaisyUI], my current favorite#footnote[favorite, for now.], which offers 14 ready-made dark themes. That's enough for me to happily waste an hour and a half comparing and picking the perfect one.

Once I've chosen that lovely dark theme, my next move is to slap a theme toggle button on the site. Because users should have a choice, right? Plus, it makes the site look pro. Everybody's doing it.
Luckily, there's a #link("https://toggles.dev")[whole website] dedicated to 12 beautiful (and animated!) toggle buttons, ready to copy and paste.
A few extra lines of wiring to connect the button to the theme logic, and voilà. I'm done.

== Theme Toggling is a Trap

Oh, wait. Not so "done" after all.
I kept gleefully switching from light to dark, dark to light, back and forth, until I accidentally refreshed the page.
Poof. My theme preference vanished.

That wasn't part of the plan. If a user picks a theme, the site should remember it, shouldn't it?
So I added code to stash the preference in `localStorage` and read it on load.
If you're a React fan like me#footnote[
  Only the good parts of React, mind you. Not those Next.js server-component backdoors.
], you can import a `useLocalStorage` hook from one of at least five actively maintained utility libraries. It saves you the trouble of writing it yourself.

```jsx
const [theme, setTheme] = useLocalStorage('theme', 'light');

useEffect(() => {
  if (theme === 'dark') {
    document.documentElement.classList.add('dark');
  } else {
    document.documentElement.classList.remove('dark');
  }
}, [theme]);

return (
  <button
    type="button"
    onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
  >
    <svg>...</svg>
  </button>
);
```

But hold on.
I casually set the default theme to `"light"`, so first-time visitors always get the bright version.
That's wrong.
Imagine a user opening my site at night, in a dark room, with their system already in dark mode. They would be blasted by a brilliant white screen. Not a great experience.

The correct approach is to check the user's system preference via the `prefers-color-scheme` media query and use that as the starting point.

```jsx
const getInitialTheme = () => {
  if (typeof window !== 'undefined') {
    const storedTheme = localStorage.getItem('theme');
    if (storedTheme) {
      return storedTheme;
    }
    const prefersDark =
      window.matchMedia('(prefers-color-scheme: dark)').matches;
    return prefersDark ? 'dark' : 'light';
  }
  return 'light'; // default on server
};
const [theme, setTheme] = useLocalStorage('theme', getInitialTheme());
```

Now the site loads in the user's preferred theme on first visit.
But what if they change their system theme _while_ browsing?
My site would ignore that, because I've already locked their choice into `localStorage`. Also not ideal.

Fix number two: add an event listener to the `prefers-color-scheme` query, so the theme updates when the system preference changes.
Thankfully, I can just grab a `useMediaQuery` hook from one of those utility libraries. Again.

```jsx
const prefersDark = useMediaQuery('(prefers-color-scheme: dark)');
const [theme, setTheme] = useLocalStorage('theme', getInitialTheme());
useEffect(() => {
  if (prefersDark) {
    setTheme('dark');
  } else {
    setTheme('light');
  }
}, [prefersDark]);
```

Now my site always respects the system theme, even if it changes mid-session. It detects the shift and updates the toggle button accordingly.
Users get a site that opens in their preferred theme and adapts seamlessly to system changes.

Yes, I finally built the "perfect" theme toggle. One that's no longer controlled by clicks, but automatically synced to the system preference.
The button's only real job now is to signal, "Hey, this site has dark mode!"

And that's when it hit me: theme toggling is never a good idea.
If it's always better to follow the system preference, why bother with a manual toggle at all?#footnote[
  Some sites offer a three-way switch: light, dark, and system.
  That's better than a two-state toggle. But honestly; I never pick an option other than "system."
]

Scrap those dozens of lines of toggle logic. Just add a few lines of CSS:

```css
@media (prefers-color-scheme: dark) {
  /* ... */
}
```

That's it.