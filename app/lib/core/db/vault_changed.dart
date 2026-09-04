/// Told whenever anything in the vault is written.
///
/// ── WHY THIS EXISTS, AND WHY IT IS NOT A LINE AT EACH SCREEN ─────────────
///
/// **Round eighteen, 3 September 2026.** *"lemme say you again and again!
/// automatic backups don't work! the way you say! I want you to check the code!
/// automatic backup is flawed at code level!"*
///
/// He had said it before and been told the feature was fixed, because the
/// backup screen said "Last backup 03/09/2026" and a sixty-megabyte file sat on
/// the disk. Both were true. Neither was an answer, because the question was
/// never "did it ever run" — it was "does it run when my journal changes".
///
/// It did not. `SilentBackup.maybeRun` declines unless
/// `AppSettings.vaultChangedSinceBackup` is set, and that flag was set by
/// `markDirty()`, which was called from **one file in the entire app**:
/// `day_screen.dart`. Every one of these changed the vault and left the flag
/// alone:
///
///   * **the journal importer** — two hundred entries brought in, and the
///     backup did not know
///   * **restoring from the trash**, and emptying it for good
///   * **creating, renaming or deleting a folder**
///   * **filing an entry into a folder** from the picker
///   * **naming a day** from anywhere but the day screen
///
/// So somebody could import their old diary, watch it appear, lock the app, and
/// have the backup quietly decide there was nothing new to save. The switch said
/// ON the whole time. That is worse than a backup that fails loudly.
///
/// ── The shape of the fix ─────────────────────────────────────────────────
///
/// The screens were never the right place to know this. **The repositories are
/// the things that write**, so they are the things that can say so — and a new
/// screen cannot forget a call it does not have to make.
///
/// Deliberately the same shape as `SystemExcursion` in `core/platform/`, for the
/// same reason and after the same failure: a rule that lives in a comment gets
/// broken by the next person, and this project has now watched that happen three
/// times in one day. Left unwired — in a test, in a tool — it does nothing at
/// all, which is the correct behaviour rather than a special case.
///
/// `every_write_marks_the_vault_test.dart` reads the repositories and fails if a
/// mutating method does not call [mark], so the eighth one cannot be written
/// without it either.
abstract final class VaultChanged {
  /// Wired once, in `app.dart`, to `SilentBackup.markDirty`.
  ///
  /// A field rather than a stream: this fires on every row written during a
  /// two-hundred-entry import, so it must cost nothing. `markDirty` sets one
  /// boolean in settings, which makes the repeat free.
  static void Function()? onWrite;

  /// Something in the vault changed, and a backup is owed.
  static void mark() => onWrite?.call();

  /// Forgets the hook, so one test's wiring does not leak into the next.
  static void forget() => onWrite = null;
}
