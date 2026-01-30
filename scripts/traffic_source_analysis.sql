USE mavenfuzzyfactory;


-- Traffic Source Analysis 
############################

SELECT DATE(MIN(created_at)) AS website_release_date
FROM website_sessions; -- 19 Mar 2012 is the date of website launch for the business.

SELECT DATE(MAX(created_at)) AS latest_available_date
FROM website_sessions; -- 19 Mar 2015 is the latest date for which the data is available.

SELECT * FROM website_sessions
WHERE website_session_id = 1059;

/* 
For a given website session, the 'website_sessions' table contains tracker information,
user information who is visiting the website, and
timestamp on when the session began.

A single user (identified by a 'user_id') can have multiple 'website sessions'. 
If a user has been to the wesbite before, the 'is_repeat_session' will be '1' (contains binary values).
*/

-- We can focus on 'utm_content': identifier of an ad-unit being run
-- 'http_referer' information is helpful for tracking in scenarios where utm trackers might not be properly deployed 

# How are website sessions distributed for each ad-unit?
SELECT utm_content, COUNT(website_session_id) AS sessions
FROM website_sessions 
WHERE YEAR(created_at) = 2012 -- Focusing only on year 2012
GROUP BY utm_content
ORDER BY sessions DESC;

/* 
It appears that 'g_ad_1' is actually super successfull in generating website sessions, in year 2012.
There appears to be a NULL contained in 'utm_content' suggesting that trackers for this source were not deployed or are unavailable.
*/

/* 
This table can also be linked with the 'orders' table to perform 'conversion rate analysis' or CVR.
CVR: number of orders placed as a proportion of total attempts made to covert a visit into a successful order.
In the context of this table, we are talking about 'session-to-order' CVR - a parameter for Return On Ad Spend (ROAS)
*/

# What is the CVR for each ad unit in 2012?
SELECT ws.utm_content, 
	COUNT(ws.website_session_id) AS sessions,
    COUNT(o.order_id) AS orders,
    (COUNT(o.order_id)/COUNT(ws.website_session_id))*100 AS cvr -- being calculated in % terms
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) = 2012 -- Focusing only on year 2012
GROUP BY ws.utm_content
ORDER BY cvr DESC;

/* 
It appears that 'b_ad_2', in year 2012, is very effective in converting sessions to sales.
This is true even though it generated least number of website sessions so far (in 2012).
*/

/*
Problem Statment 1:
Let us say that we are in the first month of the business being live and the CEO 
wants to understand where the bulk of the website sessions are coming from. Let this be a request
placed on 12-04-2012 where the CEO wants to see source information broken down into 
UTM source, campaign type and referring domain.
*/

# Solution 1:
SELECT utm_campaign, utm_source, http_referer, COUNT(website_session_id) AS sessions 
FROM website_sessions
WHERE created_at < '2012-04-12' -- Essential since the business didn't generate data further than the date at which the request was placed.
GROUP BY  utm_campaign, utm_source, http_referer;
 
/* 
It appears that the gsearch non-brand channel is the major source of website traffic and should be further investigated.
 */
 
/*
Problem Statment 2:
The marketing director wants to know the conversion rate for gsearch nonbrand channel.
According to him, the bid on channels make sense if they are resulting in at least 4% CVR.
This means bid could be increased to increase volume, but should be lowered if 4% CVR target isn't being met.
Let us say that this request came on 14th Apr 2012.
*/

# Solution 2:
SELECT ws.utm_campaign, 
		ws.utm_source, 
        COUNT(ws.website_session_id) AS sessions,
        COUNT(o.order_id) AS orders,
        ROUND((COUNT(o.order_id)/COUNT(ws.website_session_id))*100,2) AS cvr_perc
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-04-14' AND ws.utm_campaign = 'nonbrand' AND ws.utm_source = 'gsearch'
GROUP BY ws.utm_campaign, ws.utm_source
ORDER BY cvr_perc;

/* 
It appears that the gsearch non-brand channel isn't reaching the 4% CVR target. 
It should be communicated to the marketing director that there is likely over-bidding happening.
Result: The marketing director bid-downs the gsearch nonbrand channel on 2012-04-15.
*/

/*
Problem Statment 3:
The marketing director places a request on 2012-05-10 to pull gsearch nonbrand trended session volume, by 
week. He wants to see if the bid changes have caused volume to drop at all or not.
NOTE - The gsearch nonbrand channel was bid down on 2012-04-15.
*/

# Solution 3:
SELECT 
		YEAR(created_at) AS year_,
        WEEK(created_at) AS week_num,
        MIN(DATE(created_at)) AS week_start,
        COUNT(website_session_id) AS sessions
FROM website_sessions 
WHERE utm_source = 'gsearch' AND 
		utm_campaign = 'nonbrand' AND 
		created_at < '2012-05-10'
GROUP BY 1,2
ORDER BY week_start;

/* 
Weekly trend analysis reveals that the session volume has actually reduced after down-bidding took place on 2012-04-15.
Hence, gsearch nonbrand is actually sensitive to bid changes. It would be helpful to the business if there exists a way
to restore some of the sessions volume lost after bid-down took place for gsearch nonbrand channel.
*/

/*
Problem Statment 4:
The marketing director finds that the website experience on mobile device isn't great and is curious to know 
conversion rates by device type. His suggestion is that if CVR is better for a specific device, the company 
may be able to bid up specifically for that device to get more volume.
The request is placed on 2012-05-11 for gsearch nonbrand channel.
*/

# Solution 4:
SELECT 
	ws.device_type,
    COUNT(ws.website_session_id) AS sessions,
    COUNT(o.order_id) AS orders,
    (COUNT(o.order_id)/COUNT(ws.website_session_id))*100 AS cvr
FROM website_sessions ws
LEFT JOIN orders o
	ON o.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch' AND 
		ws.utm_campaign = 'nonbrand' AND 
		ws.created_at < '2012-05-11'
GROUP BY 1;

/* 
The CVR difference between mobile and desktop device is significant (0.97% v. 3.73% resp.)
The CVR for desktop device is actually very close to the target.
Result: Marketing Director chooses to increase bid on gsearch nonbrand channel specifically for 'desktop' device type
on 2012-05-19, to attain a higher ranking in the auction.
*/

/*
Problem Statement 5:
Marketing director asks to pull weekly trends for both desktop and mobile devices to assess the impact on session volume. 
The data must be pulled from 2012-04-15. The request is placed on 2012-06-09.
*/

# Solution 5:
SELECT 
	-- YEAR(created_at) AS year_,
    -- WEEK(created_at) AS week_num,
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions,
    COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
    COUNT(website_session_id) AS total_sessions
FROM website_sessions
WHERE 
	utm_source = 'gsearch' AND 
	utm_campaign = 'nonbrand' AND 
	created_at > '2012-04-15' AND
    created_at < '2012-06-09'
GROUP BY 
	YEAR(created_at),
    WEEK(created_at)
ORDER BY
	week_start_date ASC
;

/*
The bid was increased for desktop on 2012-05-19, for gsearch nonbrand channel. We can see that after this date
the number of desktop sessions actually increased in the weekly trend analysis. Since CVR was high for 'desktop' device type,
this is extremely helpful for the business in terms of higher revenue generation. What is also visible is that the number 
of mobile sessions dropped after 2012-05-19 (when bid for desktop was increased).

Another point to note is that even though mobile sessions are dropping, the total number of sessions are actually increasing after 2012-05-19.
This suggests that overall, more visits are happening on the website after prioritising 'desktop' device type for gsearch nonbrand channel.
*/


/*
NOTE:
The pivot table in MS Excel allows users to slice data into multiple dimensions and rows. They are especially helpful in 
situations where we would like to see calculated aggregations (grouped by an entity) broken-down into multiple dimensions.
SQL allows for slicing data into rows via the GROUP BY function, however slicing data into dimensions isn't as straightforward.
To achieve this CASE statements have been used here to mimic pivot_tables in Excel.
*/