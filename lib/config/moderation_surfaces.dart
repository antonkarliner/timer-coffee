/// Where a piece of user-submitted text will be shown publicly.
///
/// The backend's `content-moderation` function forwards this to its
/// classifier as the `where_it_appears` field, alongside the text itself. It
/// changes the verdict: a handle-shaped string is ordinary in a display name
/// and suspicious in a brew step, and recipe numbers (`1:16.67`, `12-15 s`)
/// look like phone numbers without that context.
///
/// These four values are the only ones the classifier's rubric was evaluated
/// against, which is why they are constants rather than free-form strings.
/// The field is optional on the wire: an unknown or missing value is not an
/// error, but it falls back to a generic label that carries no evaluation
/// evidence. Always send one when the surface is known.
///
/// Note there is no value for a profile picture. Images take a different
/// branch in the function (`imageBase64`), which never reaches this
/// classifier.
class ModerationSurfaces {
  ModerationSurfaces._();

  /// A public review of a coffee bean.
  static const String review = 'review';

  /// A public brewing recipe: name, description, grind and steps, joined
  /// into one text.
  static const String recipe = 'recipe';

  /// The public display name on a user profile.
  static const String displayName = 'display_name';

  /// A New Year greeting sent to a random other user. Submitted through
  /// `submit-yearly-wish`, which sets this server-side.
  static const String wish = 'wish';
}
