# Spec: Instructor Analytics Dashboard (v1)

Status: ready-for-agent

## Problem Statement

When instructors log in, they land on the generic course catalogue. Their own area is only a list of their courses with lesson and enrollment counts. Instructors can't see how much they earn, how many students finish their courses, or where students give up. Without that, they can't tell which courses work or which lessons need improving.

## Solution

The instructor area's main page becomes an analytics dashboard and is where instructors land after login. The top of the page shows:

- Stat tiles with all-time and last-30-day figures for earnings, enrollments, active students, completion rate and average progress.
- Two weekly charts covering the last 12 weeks: earnings and new enrollments.

Below that is the instructor's course table, with metric columns added. Each course links to a new per-course analytics page. That page shows the course's metrics and a lesson drop-off funnel: the share of enrolled students who completed each lesson, in course order, with the biggest drop highlighted.

All metrics are computed live from the database on each request.

## User Stories

1. As an instructor, I want to land on my analytics dashboard after logging in, so that I immediately see how my courses are doing.
2. As an instructor, I want to land on my analytics dashboard after signing up, so that new instructors get the same starting point.
3. As an instructor who followed a link to a specific page before logging in, I want to be returned to that page rather than the dashboard, so that login doesn't lose my place.
4. As an instructor, I want a "Dashboard" entry in the sidebar, so that I can get back to the dashboard at any time.
5. As an instructor, I want to see my total all-time earnings, so that I know how much I've made on the platform.
6. As an instructor, I want to see my earnings for the last 30 days, so that I know how I'm doing right now.
7. As an instructor, I want earnings labelled as gross (before any platform fee), so that I don't misread the figure.
8. As an instructor, I want earnings to reflect the price students actually paid, including PPP-discounted prices, so that the figure matches real revenue.
9. As an instructor, I want team seat purchases of my courses counted in full on the purchase date, so that bulk sales show up as earnings.
10. As an instructor, I want earnings shown in dollars and cents, so that the figure is easy to read.
11. As an instructor, I want a weekly earnings chart for the last 12 weeks, so that I can see trends.
12. As an instructor, I want to see total enrollments and enrollments in the last 30 days, so that I know how many students I'm reaching.
13. As an instructor, I want students who joined through a team coupon counted as enrollments, so that the figure reflects everyone taking my course.
14. As an instructor, I want a weekly new-enrollments chart for the last 12 weeks, so that I can see whether my audience is growing.
15. As an instructor, I want to see how many distinct students were active in the last 7 days, so that I know current engagement.
16. As an instructor, I want to see how many distinct students were active in the last 30 days, so that I can compare short-term and monthly engagement.
17. As an instructor, I want a student to count as active when they complete a lesson, attempt a quiz or watch a video, so that every kind of learning activity is reflected.
18. As an instructor, I want to see the overall completion rate across my courses, so that I know what share of students finish.
19. As an instructor, I want a course to count as completed only when the student has completed every lesson currently in it, so that the rate means what it says.
20. As an instructor, I want to see the average progress of my students, so that I understand engagement beyond yes/no completion.
21. As an instructor, I want a table of all my courses showing enrollments, earnings, completion rate and average progress per course, so that I can compare courses.
22. As an instructor, I want draft and archived courses included in the table with their status shown, so that past earnings and unpublished work aren't hidden.
23. As an instructor, I want to reach course management (editing a course, its student list, creating a new course) from the dashboard, so that the dashboard doesn't make course management harder to reach.
24. As an instructor, I want to open an analytics page for a single course, so that I can dig into it.
25. As an instructor, I want the course analytics page to show that course's earnings (all-time and last 30 days), enrollments, completion rate and average progress, so that I can judge the course on its own.
26. As an instructor, I want a lesson drop-off funnel showing, for each lesson in course order, the percentage of enrolled students who completed it, so that I can see where students stop.
27. As an instructor, I want the funnel ordered by module, then lesson, matching the course outline, so that it reads like the course.
28. As an instructor, I want funnel lessons labelled with their module and lesson title, so that I can find them.
29. As an instructor, I want the lesson with the biggest drop from the previous lesson highlighted, so that I know which lesson to improve first.
30. As an instructor, I want a drop on the very first lesson (students who enrolled but never completed anything) to be eligible as the biggest drop, so that a weak opening lesson isn't hidden.
31. As an instructor, I want a link from the course analytics page back to the dashboard, so that I can move between them easily.
32. As an instructor with no courses yet, I want an empty state with a "Create your first course" link, so that I know what to do next.
33. As an instructor, I want rates on a course with no enrollments shown as "—" rather than 0%, so that I'm not misled.
34. As an instructor, I want charts with no data to show a "No data yet" message, so that the page doesn't look broken.
35. As an instructor, I want weeks with no activity shown as zero in the charts, so that gaps are visible rather than skipped.
36. As an instructor, I should not be able to see analytics for another instructor's course, so that each instructor's data stays private.
37. As an instructor, I want to see a "not found" response for a course that doesn't exist, so that bad links fail clearly.
38. As a student, I should not be able to access the instructor dashboard or course analytics, so that the data is restricted to instructors.
39. As a user who isn't logged in, I should not be able to access the instructor dashboard or course analytics, so that nothing leaks publicly.
40. As a developer demoing the platform, I want demo data spread over about 90 days for both instructors, so that the charts and funnel show meaningful shapes.

## Implementation Decisions

### Metric definitions

These are the source of truth. Use them consistently everywhere.

- **Earnings:** the sum of the price paid (in cents) on purchases of the instructor's courses, dated by the purchase date.
  - It is gross: no platform fee, and refunds aren't modelled.
  - A team purchase counts in full on its purchase date. Coupon redemptions add no earnings.
  - Display in USD.
- **Enrollment:** any enrollment record, including enrollments that came from a team coupon. "New enrollments" are dated by the enrollment date.
- **Completed:** an enrolled student has a completed lesson-progress record for every lesson currently in the course.
  - Quizzes aren't required, and the enrollment's own completion timestamp is not used.
  - Lessons added later count against students who have already finished.
- **Completion rate:** completed enrollments ÷ enrollments. It is "no value" (shown as "—") when there are no enrollments.
- **Progress (per student):** completed lessons ÷ current lesson count in the course, unweighted and without quizzes.
  - **Average progress** is the mean of that figure across enrollments. It is "no value" when there are no enrollments.
  - Overall figures across courses average over all of the instructor's enrollments.
- **Active student:** a distinct user, enrolled in one of the instructor's courses, with at least one of these in the window, scoped to that instructor's courses:
  - a lesson-completion timestamp
  - a quiz-attempt timestamp
  - a video-watch-event timestamp
- **Drop-off funnel:** lessons are ordered by module position, then lesson position. For each lesson: students who completed it ÷ enrollments.
  - **Biggest drop** is the lesson with the largest decrease in percentage points from the previous lesson. The first lesson is compared against 100%.
- **Windows:** "last 30 days" and "last 7 days" are rolling from now. The weekly charts cover the last 12 weeks, one bucket per week, ending with the current week. Empty weeks are zero-filled.
- **Scope:** every course the instructor owns, regardless of course status.

### Analytics service (new module)

- A new service module, following the project convention: a flat set of exported functions with positional parameters, querying through the shared database handle.
- It is the only place analytics are computed. Routes call it and render the results.
- Aggregate in SQL (group-by and count/sum). Don't loop over students or lessons with one query each. Existing per-user progress helpers are not reused for aggregates.
- Every time-dependent function takes the current time as a parameter, so results are deterministic in tests.
- Rates come back as "no value" (null) when there are no enrollments, and the UI renders them as "—".
- Interface: final names are up to the implementer, but it covers:
  - **Instructor overview:** earnings (all-time and 30 days), enrollments (all-time and 30 days), active students (7 and 30 days), completion rate and average progress.
  - **Per-course metrics** for an instructor: one row per course with id, title, status, enrollments, earnings, completion rate and average progress.
  - **Weekly earnings** and **weekly new enrollments** for an instructor: 12 zero-filled buckets, each with a week-start date and a value.
  - **Course analytics:** course-level metrics plus the funnel. Each funnel entry has lesson id, module title, lesson title, completed count and percent, plus the biggest-drop lesson id.

### Routes and navigation

- **Instructor home** (the existing instructor courses page) is rewritten as the dashboard.
  - Access is limited to the Instructor role, as it is today; admins stay excluded.
  - It loads the overview, the weekly series and the per-course metrics.
  - The page shows stat tiles, the two charts and the course table. Each course row links to its analytics page and to the existing editor and students pages, and there is a "New course" action.
- **Course analytics page:** a new route nested under the instructor course path.
  - The course id is validated with the shared param validation helper.
  - Access requires the Instructor role and that the user owns the course. Otherwise it responds 403, or 404 when the course doesn't exist.
  - The page shows course tiles and the drop-off funnel chart, and links back to the dashboard.
- **Login and signup:** when no explicit redirect target is provided, users with the Instructor role are sent to the dashboard. Everyone else keeps the current default (the course catalogue).
- **Sidebar:** the instructor entry "My Courses" is renamed to "Dashboard" and still points to the instructor home.

### UI

- Add shadcn's chart component, which brings in Recharts.
- Charts:
  - Weekly earnings: bars or area.
  - Weekly enrollments: bars.
  - Drop-off funnel: bars per lesson, with the biggest-drop bar in an accent colour.
- Stat tiles use the existing card component.
- Empty states:
  - No courses: a message plus a link to course creation.
  - All-zero series: "No data yet" in place of the chart.

### Seed data

Extend the seed script so both instructors have about 90 days of activity:

- Purchases, including a PPP purchase and a team purchase.
- Enrollments spread across the window.
- Lesson progress of varied depth, so the funnel shows a visible drop-off.
- Some quiz attempts and video watch events, so active-student counts are non-trivial.

### Schema

None. Every metric derives from existing tables.

## Testing Decisions

- **One seam: the analytics service's public functions.** Every metric is verified there. There are no route, UI or login-redirect tests, consistent with the rest of the repo.
- **What makes a good test:** it seeds data, calls a public service function with a fixed "now", and asserts on the returned figures. It never asserts on queries, table shapes or internal helpers, so the SQL can be rewritten freely.
- **Prior art:** the existing service tests. Each test builds a fresh in-memory database with the base seed data (a student, an instructor, a category, a published course), and the database module is mocked through a getter.
- Cover:
  - **Earnings:** sums the price paid, including PPP prices and team purchases. Excludes other instructors' courses. The 30-day window boundary.
  - **Enrollments:** coupon-based enrollments count, and add no earnings.
  - **Completion:** completed only when every current lesson is completed. Adding a lesson makes a completed student incomplete. "No value" when there are no enrollments.
  - **Average progress:** a mixed set of students.
  - **Active students:** each of the three activity sources counts. Activity outside the window doesn't. Students are counted once. Activity on another instructor's course is excluded.
  - **Weekly series:** 12 buckets, zero-filled, with correct bucketing near week boundaries.
  - **Funnel:** ordered by module position, then lesson position. Correct percentages. The biggest-drop lesson is identified, including when the biggest drop is the first lesson.
  - **Course metrics:** draft and archived courses are included, with their status.
- The test suite and the typecheck must both pass.

## Out of Scope

- Platform fees, revenue share, net earnings, refunds and payouts.
- An admin or platform-wide analytics view.
- A custom date-range picker, and time windows other than those listed.
- Pre-computed snapshots, rollup tables and background jobs.
- Video-level (within-lesson) drop-off and watch-time analytics.
- Ratings and reviews (no data exists).
- CSV export.
- Per-student drill-down beyond the existing course students page.
- Refactoring the existing quiz-scoring or per-user progress code.

## Further Notes

- The metric definitions are deliberately simple and consistent with each other: completion, average progress and the funnel all use completed lessons ÷ current lesson count.
- The existing course students page computes progress per student with nested loops. It is left as is; the new service is the place to aggregate.
- With the current seed data, revenue can't be derived from enrollments × price: coupon-based enrollments have no purchase, and PPP purchases are discounted. Always sum the actual purchases.
