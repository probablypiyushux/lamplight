# Reality check

*Written 17 Aug 2026, in answer to: "Am I going right? Would my idea work fine?"*

An honest assessment. Not encouragement, not discouragement — the actual state of things,
including the parts that are uncomfortable.

---

## Where the idea is genuinely strong

**1. The security architecture is sound and it is buildable.**
This is not a small thing. Most people who set out to build "a secure app" propose something
that cannot work — a backdoor they haven't noticed, a server they can't afford, key handling
that falls apart the first time someone changes their password. The design in
`02-security/` uses standard primitives in standard ways and has no such hole in it. It is
a *solved problem*. That means the hardest-sounding part of your idea is actually the part
that is most under control.

**2. The zero-server decision is a structural advantage, not a feature.**
Every competitor pays a monthly bill that grows with their user count. That bill is why free
apps eventually sell data, add ads, or shut down. Yours costs the same at 10 users and at
100,000: nothing. **Which means it can never fail for business reasons.** A solo project that
cannot run out of money is a solo project that can quietly exist for a decade. Almost nothing
else in this category can say that.

**3. The scope is achievable.** Ambitious, not delusional. One person with AI help can build
this in months. That's a rarer property than it sounds.

**4. You have taste, and you know what you want it to feel like.**
*"Recording his experiments or recording his feelings... a particular phase or particular
person."* That's a product insight, not a feature list, and it's the thing that can't be
copied. Most technical founders never get there.

---

## Where it's harder than you think

### 1. 🔴 The category is brutally crowded

Encrypted notes and private journalling are among the most saturated app categories that
exist. Products already shipping, most of them for years, most of them open source:

- **Standard Notes** — E2E encrypted notes, open source, audited, established
- **Notesnook** — E2E encrypted notes, open source, actively developed, well-marketed
- **Obsidian** — local-first, huge community
- **Day One** — the journalling market leader
- **Journey, Diarium, Mini Diarium** — private journals, several offline-first

None of this means stop. It means **"it's encrypted" is not a differentiator in 2026.** It's
table stakes. If your pitch is "secure notes app," you're the twelfth one and you'll lose to
the ones with four years of polish and an actual audit.

### 2. 🟢 But there *is* a real gap, and it isn't where you think

Look at what those competitors actually are:

- The encrypted-notes apps (Standard Notes, Notesnook) are **text-first, with accounts and
  cloud sync.** They're built for notes, not for a life. No voice-first capture, no day tabs.
- The journal apps (Day One, Journey) have **the day model and the media capture** — but they
  all have accounts, servers, and cloud sync, because that's their business model.

**Nobody is properly occupying: a voice-and-photo life journal with literally no account and
literally no server.** That combination — the daily tab, one-tap voice, photos, documents,
folders that thread across years, and *nothing leaves the phone unless you export it yourself*
— is a genuine hole.

So **your differentiator is not encryption. It's the total absence of an account, combined
with capture that isn't text.** Lead with that. "There is no account" is a stranger and more
memorable sentence than "it's encrypted," and unlike encryption, it's instantly verifiable by
anyone who opens the app.

### 3. 🔴 Building it is maybe 30% of the work. Getting anyone to use it is 70%.

This is the thing almost every first-time developer gets wrong, and it's worth sitting with.
You will spend months building, ship it, and then discover that shipping is the starting line.
Most solo apps get under 100 installs, ever — not because they're bad, but because nobody
knows they exist and the developer had no plan for that part.

You can't buy your way out (no budget) so it has to be earned: build in public, post progress,
write about the design decisions, be present in r/privacy and r/androidapps and Hacker News
*before* you launch, not on launch day. **Start this in Phase 2, not Phase 8.** The people who
watched you build it are the people who install it.

### 4. 🔴 Journalling apps have terrible retention

Most people journal for about nine days. This is a property of journalling, not of your app.
It means: the daily loop has to be effortless, the app has to be beautiful enough to *want* to
open, and the year grid has to make people feel something. Those aren't polish items — they're
the product.

It also means you should measure success by *"do I still use it in month six?"* rather than by
install count.

### 5. 🟠 You cannot audit your own code. This is the real risk.

You're shipping a security product whose implementation you can't personally verify. If a
subtle crypto bug gets written, you will not catch it. That's not a knock on you — it's just
true, and pretending otherwise would be the dangerous move.

What to do about it, in order:
- **Keep the claims conservative until an audit exists** (ADR-008). This is the single most
  important protection you have, and it's free.
- **Keep `core/crypto` small.** An auditor — paid or volunteer — should be able to read the
  whole security-critical surface in an afternoon.
- **Ask Claude Code for the crypto tests obsessively**, and for adversarial ones: wrong key,
  tampered ciphertext, truncated file, reordered chunks.
- **Publish the threat model and invite attack.** People who break things for fun are free
  security review, and they show up for open-source privacy projects.
- **Budget for a real audit eventually** if this becomes something real.

---

## So: are you going right?

**Yes, on the decisions.** Every fork so far — no account, encrypted file backup, recovery
phrase, Flutter, GitHub before Play Store — you either got right yourself or accepted the
right answer immediately when the reasoning was laid out. That's the part that's hard to teach
and it's the part you're doing well.

**Yes, on the idea.** There's a real gap, and it's a gap you found by describing a feeling
rather than a feature.

**The idea is not the risk.** The risks are: finishing (most solo projects die in month three),
distribution (nobody will find it by accident), and your inability to verify your own security
claims (manageable, if you stay conservative about what you say in public).

## The most useful reframe

Stop asking *"will this succeed?"* — it's unanswerable and it'll paralyse you.

Ask instead: **"if only I ever use this, was it worth building?"**

If the honest answer is yes — you get a private record of your own life in an app built exactly
how you want it, and you learn to ship software from nothing — then the downside is capped at
*something genuinely good*, and everything above that is upside. That's an unusually favourable
bet, and it's the reason to start.

Given that you've never built an app before, the most likely outcome by far is **that you learn
an enormous amount and end up with something you personally use every day.** That is not a
consolation prize. That's the realistic good case, and it's worth having.

---

## Sources

- [Notesnook vs Standard Notes comparison (2026)](https://openalternative.co/compare/notesnook/vs/standard-notes)
- [7 Best Encrypted Note-Taking Apps in 2026](https://securenotesvault.com/blog/best-encrypted-notes-apps)
- [Best Private Journaling Apps 2026](https://www.therma.one/best/private-journaling-apps)
- [7 Best Day One Alternatives in 2026](https://getmindspace.app/day-one-alternatives/)
- [Best Open Source Note Taking Apps in 2026](https://toolfinder.com/best/open-source-note-taking-apps)
