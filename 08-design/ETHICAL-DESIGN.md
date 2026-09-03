# Ethical design — "no malpractice"

*You said: "No malpractice!" This is what that means, made specific enough to hold yourself to.*

A dark pattern is any design that gets the user to do something they wouldn't have chosen. They
work — that's why they're everywhere — and every single one of them would be **more** effective
in a journalling app than in a normal one, because the content is emotional and the user is
vulnerable when they're using it.

**That's exactly why the answer is no.** An app that holds someone's private feelings and then
manipulates them with those feelings is doing something worse than an ad-supported game doing
the same. The trust required here is unusual, and it's spent once.

---

## The charter

### 1. Never manufacture guilt
❌ No streaks. No "you broke a 47-day run." No red badges counting missed days. No
guilt-shaped notifications.

People stop journalling during depression, grief, illness, newborns, crises — **precisely when
they most need the app not to punish them.** A streak counter converts a difficult month into a
visible failure, and the reliable result is that people delete the app rather than face it.

✅ The year grid shows what you *did*, never what you didn't. Gaps are neutral, not red.
Returning after three months should feel like coming home, not like being caught.

### 2. Never manipulate to retain
❌ No "we miss you." No fake urgency. No artificial scarcity. No notification designed to pull
someone back who chose to leave.
✅ One optional daily reminder, off by default, plain wording, easy to turn off in one tap.

### 3. Never obstruct leaving
❌ No hiding the export. No making deletion take six screens. No "are you *sure*? you'll lose
everything!" guilt-modals on the way out.
✅ **Export is a first-class feature, sitting in plain sight.** Delete-everything is findable
and works. The strongest signal that an app respects you is how easy it is to walk away with
your data, and this one's whole architecture is built on the user being able to.

### 4. Never make privacy the expensive option
❌ No "upgrade to Pro for encryption." No paid privacy tier.
✅ Full security for everyone, always. Privacy is not a feature; it's the floor.

### 5. Never use confusing consent
❌ No pre-ticked boxes. No "Not now" that means "ask again tomorrow forever." No accept button
styled large and green with decline as grey 11px text.
✅ Yes and No are the **same visual weight**. "No" is genuinely permanent. Every default is the
private one.

### 6. Never lie about safety, in either direction
❌ No "military-grade", "unbreakable", "NSA-proof", "100% secure." (ADR-008.)
❌ Equally: no hiding the limits. The threat model is published, including the parts where the
answer is "we cannot protect you against this."
✅ Say exactly what's true. *"Designed so we cannot read your notes"*, plus a link to the honest
list of what that does and doesn't cover.

### 7. Never make loss feel like the user's fault
The one-time recovery phrase means some people will lose everything. That's the correct
trade-off, but it obliges you to be honest and generous about it:
✅ Warn clearly and repeatedly at setup, in plain words. Make backup obvious and easy. If
someone does lose their vault, respond with genuine sympathy, not "you were warned." **You
designed a system where this outcome is possible — you don't get to be smug when it happens.**

### 8. Never encode meaning in colour alone
Both an accessibility rule and an honesty rule: a design that only works for some eyes is a
design that quietly excludes people. Every colour-carried state also carries a shape, icon,
label, or position. (See `ACCESSIBILITY.md`.)

### 9. Never let the business model want their data
There is no data to want. Free, with an optional donation link. **Never ads, never data
brokerage, never "anonymised insights."**

The reason to write this down now, while there are zero users, is that it's easy now. It will
be harder the day someone offers you money for aggregate mood data from ten thousand journals.
Decide before you're tempted.

### 10. Never dress up a limitation as a feature
If something is missing because it was hard, say it was hard. Don't call an absent feature
"intentional minimalism." Users can tell, and the ones who can't are the ones you'd be fooling.

---

## The three tests

Before shipping any screen, flow, or piece of copy:

**1. The disclosure test.** Would I be comfortable explaining, out loud, exactly why this
element is designed this way? If the honest explanation is *"because it increases retention"*
rather than *"because it helps the user"* — cut it.

**2. The vulnerable-user test.** Someone is opening this app at 3am after the worst day of
their life. Does this screen help them, or does it want something from them?

**3. The reversal test.** If a competitor did this to me, would I think it was scummy? Then it's
scummy when you do it.

---

## Where this actually gets tested

Not in the abstract — in these specific moments, all of which are coming:

- **The backup nag.** It's a genuine safety feature and it's also, structurally, a
  retention-shaped notification. Keep it: quiet banner, dismissible, never a modal, never a
  badge, wording that escalates in *clarity* and never in pressure.
- **The empty first day.** The temptation to add a prompt that guilts someone into writing. A
  question is fine. Pressure is not.
- **The year grid.** The single most likely place for streaks to sneak in, because the shape
  invites it. Show what happened. Never count what didn't.
- **The moment you want more users.** Every growth tactic that works is on the list above.

## The one-line version

> **Design as if the person using this at 3am is someone you love.**
