# Spec: Lesson Comments (v1)

Status: ready-for-agent

## Problem Statement

Students working through a lesson have nowhere inside Cadence to ask a question about it or discuss it with classmates and the instructor. Questions end up in external channels, if they are asked at all. Instructors can't see where students get stuck, and later students can't benefit from answers to questions already asked.

## Solution

Each lesson gets a discussion section below its content. People enrolled in the course, the course's instructor and admins can read and post comments. Comments are markdown, so code blocks can be included. Comments are threaded with one level of replies. Authors can edit and delete their own comments. The course instructor's comments are marked with an "Instructor" badge, and the instructor and admins can remove any comment.

## User Stories

1. As an enrolled student, I want to see a discussion section below the lesson content, so that I can read what others have asked about this lesson.
2. As an enrolled student, I want to post a comment on a lesson, so that I can ask a question about it.
3. As an enrolled student, I want to write my comment in markdown, so that I can include formatted text and code blocks.
4. As an enrolled student, I want code blocks in comments to render in monospace, so that pasted code is readable.
5. As an enrolled student, I want to reply to a top-level comment, so that I can answer a classmate's question or continue a discussion.
6. As an enrolled student, I want replies to appear grouped under the comment they answer, so that conversations are easy to follow.
7. As an enrolled student, I want comments and replies ordered oldest first, so that threads read chronologically.
8. As an enrolled student, I want to see each commenter's name and avatar, so that I know who said what.
9. As an enrolled student, I want to see when each comment was posted (relative time), so that I can judge how current it is.
10. As an enrolled student, I want to edit my own comment, so that I can fix mistakes or add detail.
11. As an enrolled student, I want edited comments to show an "edited" marker, so that readers know the text changed after posting.
12. As an enrolled student, I want to delete my own comment, so that I can remove something I no longer want posted.
13. As an enrolled student, I want to be asked to confirm before deleting, so that I don't delete something by accident.
14. As an enrolled student, I want a deleted comment that has replies to remain as a "[deleted]" placeholder, so that the replies still make sense.
15. As an enrolled student, I want deleted comments without replies to disappear entirely, so that the discussion isn't cluttered.
16. As an enrolled student, I want posting, editing and deleting to happen without a full page reload, so that I keep my place in the lesson.
17. As an enrolled student, I want a clear error message if my comment is empty or longer than 5,000 characters, so that I know how to fix it.
18. As an enrolled student, I want to recognise the course instructor's comments by an "Instructor" badge, so that I can spot authoritative answers.
19. As an enrolled student, I want to be unable to edit or delete other people's comments, so that discussions can't be tampered with.
20. As an enrolled student, I want malicious HTML or scripts in comments to be neutralised, so that reading the discussion is safe.
21. As a course instructor, I want to read and post comments on lessons in my course without being enrolled, so that I can answer students.
22. As a course instructor, I want my comments badged as "Instructor", so that students know who is answering.
23. As a course instructor, I want to delete any comment on my course's lessons, so that I can remove inappropriate content.
24. As an admin, I want to read, post and delete any comment on any lesson, so that I can moderate the platform.
25. As a visitor who isn't enrolled, I should not see or be able to post comments, so that discussions stay inside the course.
26. As a user who isn't logged in, I should not be able to post, edit or delete comments, so that every comment has an accountable author.
27. As a student who lost enrollment (for example after a refund), I should no longer be able to read, post, edit or delete comments, so that access matches enrollment.
28. As an enrolled student, I want comments from people who later lost enrollment to stay visible, so that threads I took part in stay intact.
29. As an instructor of a different course, I should not be able to moderate this course's comments, so that moderation follows course ownership.
30. As a student, I want links in comments to be clickable but marked nofollow, so that links are useful without being an SEO spam vector.

## Implementation Decisions

- **Schema:** new `lesson_comments` table following existing conventions (integer autoincrement id, snake_case columns, ISO-text timestamps via `$defaultFn`):
  - `id`
  - `lessonId` → lessons, cascade on delete
  - `userId` → users
  - `parentId` → lesson_comments, nullable. It must reference a top-level comment, so the depth is at most one.
  - `body`: the raw markdown text
  - `createdAt`
  - `editedAt`: nullable
  - `deletedAt`: nullable
  - An index on `lessonId`.

  The migration is generated with drizzle-kit.
- **Storage format:** comments are stored as raw markdown and rendered on read, never stored as HTML.
- **Comment service (new deep module):** a function module next to the existing services. Every mutating function takes the acting user and enforces permissions internally:
  - `listForLesson(viewer, lessonId)`: checks read access and returns threads (top-level comments with nested replies), ordered oldest first. Each comment carries rendered HTML, author name and avatar, an `isInstructor` flag, an `edited` flag, and permission flags for the viewer (`canEdit`, `canDelete`). Deleted comments come back as `[deleted]` placeholders with no body when they still have visible replies, and are left out otherwise. Deleted replies are always left out.
  - `create(actor, { lessonId, body, parentId? })`: the actor needs access. It rejects a `parentId` that is a reply, belongs to another lesson, or is deleted.
  - `edit(actor, commentId, body)`: only the author, and only while the author still has access. Sets `editedAt`. Deleted comments can't be edited.
  - `softDelete(actor, commentId)`: the author, the course instructor or an admin. Sets `deletedAt` and clears `body`.
  - `canModerate(user, course)`: true for the course's instructor (`courses.instructorId`) and for admins.
- **Access rule:** a user can read and write a lesson's comments if they are enrolled in its course, are the course's instructor, or are an admin. The rule is re-checked on every action, including edits to a user's own comments.
- **Errors:** the service throws typed errors (forbidden, not found, invalid) that the route maps to HTTP responses or form errors.
- **Comment markdown renderer:** a separate server-only render function. It doesn't reuse the lesson renderer, which is unsanitized and uses Shiki.
  - marked runs with raw HTML escaped.
  - The output goes through `sanitize-html` with a tight allowlist: p, br, strong, em, del, a, ul, ol, li, code, pre and blockquote.
  - Links only allow http, https and mailto, and are forced to `rel="nofollow noopener"` with `target="_blank"`.
  - There's no syntax highlighting.
- **Lesson route:**
  - The loader calls `listForLesson` and returns the threads, plus the course instructor id for badging.
  - The action adds the intents `add-comment`, `edit-comment` and `delete-comment` to the existing intent dispatch, validated with Zod through the existing form-data helper. The body is trimmed and must be 1–5,000 characters.
- **UI:**
  - A comments section below the lesson content, built from existing shadcn components.
  - Posting, editing and deleting go through `useFetcher`, with no optimistic updates.
  - Edit happens in place in a textarea. Delete asks for confirmation.
  - "Reply" appears on top-level comments only.
  - Errors are shown as `sonner` toasts or inline form errors.
- **Seed data:** the seed script adds a few example threads, including an instructor reply and a soft-deleted parent that has replies.

## Testing Decisions

- Tests check external behaviour through the service's public functions, not internal queries or table shapes.
- **Primary seam:** the comment service, tested with Vitest against an in-memory database built by the existing test DB helper with the base seed data. It follows the existing mock-the-db-module pattern used by the other service tests. The tests cover:
  - Access: an enrolled student, a stranger who isn't enrolled, the course instructor, an instructor of another course, an admin, and a student whose enrollment was removed.
  - Creating top-level comments and replies. Rejecting a reply to a reply, a parent on another lesson, and a deleted parent.
  - Ordering, and grouping comments into threads.
  - Editing: allowed for the author only, sets the edited flag, and isn't allowed on deleted comments.
  - Soft delete by the author, the instructor and an admin. Forbidden for other students. The body is cleared afterwards.
  - Display after deletion: a placeholder when visible replies exist, hidden otherwise.
  - The instructor flag and the viewer permission flags.
- **Secondary seam:** the comment markdown renderer, as a pure unit test. It covers:
  - Script tags, event-handler attributes, `javascript:` URLs and raw HTML are neutralised.
  - Links get `rel="nofollow noopener"`.
  - Code blocks and basic formatting survive.
- Prior art: the existing service tests (for example the lesson service tests) and the test setup helper.
- There are no route or UI tests, consistent with the rest of the repo.

## Out of Scope

- Notifications of any kind: in-app or email.
- Reactions or upvotes, accepted answers, pinning, @mentions.
- Flagging or reporting comments, and moderation queues.
- Real-time updates (WebSockets or polling).
- Rate limiting and pagination.
- Comments anchored to a section or line within a lesson.
- Comment counts shown outside the lesson page, and an instructor inbox across lessons.
- Syntax highlighting in comments.

## Further Notes

- This partly delivers backlog idea #26 (Discussion Forum per Lesson). Pinning and accepted answers are deferred.
- The existing lesson markdown renderer injects unsanitized HTML. That's fine for content from trusted instructors, but it must never be used for comments.
