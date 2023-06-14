/* SQL Mini-Project, Dann Albright */

/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name
FROM Facilities
WHERE membercost > 0


/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(*)
FROM Facilities
WHERE membercost = 0

/* 4 */


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost > 0
	AND membercost < (0.2 * monthlymaintenance)

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN (1, 5)

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

/* Note: above instructions kind of ambiguous. Wrote two options: */

/* Option 1 */

SELECT name, monthlymaintenance, expense_label
FROM Facilities

/* Option 2 */

SELECT name AS cheap, monthlymaintenance FROM Facilities WHERE expense_label = 'cheap'
SELECT name AS expensive, monthlymaintenance FROM Facilities WHERE expense_label = 'expensive'


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (SELECT MAX(joindate) from Members)


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT f.name AS Court, concat(m.firstname, ' ', m.surname) AS Name
FROM Bookings AS b
INNER JOIN Members AS m USING(memid)
INNER JOIN Facilities AS f USING (facid)
WHERE f.name LIKE 'Tennis Court%'
ORDER BY m.surname, m.firstname


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT f.name AS Facility,
    concat(m.firstname, ' ', m.surname) AS Name,
    IF(b.memid = 0, b.slots * f.guestcost, b.slots * f.membercost) AS Cost
FROM Bookings as b
INNER JOIN Facilities AS f USING(facid)
INNER JOIN Members AS m USING (memid)
WHERE starttime LIKE '2012-09-14%'
	AND IF(b.memid = 0, b.slots * f.guestcost > 30, b.slots * f.membercost > 30)
ORDER BY Cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT c.Facility, c.Name, c.Cost
FROM
	(SELECT f.name AS Facility,
    	concat(m.firstname, ' ', m.surname) AS Name,
    	IF(b.memid = 0, b.slots * f.guestcost, b.slots * f.membercost) AS Cost
	FROM Bookings as b
	INNER JOIN Facilities AS f USING(facid)
	INNER JOIN Members AS m USING(memid)
	WHERE starttime LIKE '2012-09-14%') AS c
ORDER BY Cost DESC


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

import sqlalchemy as db
import pandas as pd
engine = create_engine('sqlite:///sqlite_db_pythonsqlite.db')
with engine.connect() as con:
    print(pd.read_sql('SELECT rev.Name, rev.Revenue \
    	FROM (SELECT f.name as Name, SUM(CASE WHEN b.memid = 0 THEN b.slots * f.guestcost \
   	ELSE b.slots * f.membercost END) AS Revenue \
    	FROM Bookings AS b INNER JOIN Facilities AS f USING(facid) \
    	GROUP BY f.name ORDER BY Revenue) AS rev \
    	WHERE Revenue < 1000', con))

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

import sqlalchemy as db
import pandas as pd
engine = create_engine('sqlite:///sqlite_db_pythonsqlite.db')
with engine.connect() as con:
    print(pd.read_sql('SELECT m1.surname AS "Member Last", m1.firstname AS "Member First", \
        m2.surname AS "Recommender Last", m2.firstname AS "Recommender First" \
        FROM Members as m1 \
        LEFT JOIN Members as m2 \
        ON m1.recommendedby = m2.memid \
        ORDER BY "Member Last", "Member First"', con))

/* Q12: Find the facilities with their usage by member, but not guests */

/* Following is each facility's usage by member, then each facility's usage by members overall. */

with engine.connect() as con:
    print(pd.read_sql('SELECT f.name, m.firstname || " " || m.surname AS Member, \
        SUM(b.slots) as Total \
        FROM Bookings as b \
        LEFT JOIN Facilities as f USING(facid) \
        LEFT JOIN Members as m USING(memid) \
        WHERE memid <> 0 \
        GROUP BY name, Member \
        ORDER BY name, total DESC', con))

with engine.connect() as con:
    print(pd.read_sql('SELECT f.name, SUM(b.slots) as Total \
        FROM Bookings as b \
        LEFT JOIN Facilities as f USING(facid) \
        LEFT JOIN Members as m USING(memid) \
        WHERE memid <> 0 \
        GROUP BY name \
        ORDER BY name', con))


/* Q13: Find the facilities usage by month, but not guests */

with engine.connect() as con:
    print(pd.read_sql('SELECT f.name AS Facility, STRFTIME("%m", b.starttime) AS Month, \
        SUM(b.slots) AS "Member Usage" \
        FROM Bookings as b \
        LEFT JOIN Facilities as f \
        USING(facid) \
        WHERE memid <>0 \
        GROUP BY f.name, Month \
        ORDER BY Facility, Month', con))
