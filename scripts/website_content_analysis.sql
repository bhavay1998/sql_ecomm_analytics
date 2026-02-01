USE mavenfuzzyfactory;

-- Website Content & Conversion Funnel Analysis
##################################################

/*
The table that contains the core information about website content
is the 'website_pageviews' table.
*/

# How to track the order of pages in which a user browsed the website?
	-- This can be done by filtering for a particular website session.
SELECT * FROM website_pageviews
WHERE website_session_id = 6 -- Filter for a particular session
ORDER BY created_at -- the entire order of pageviews for a session is visible now.
; 

/*
For website_session_id = 6, the /home page appears to be the 1st page that customer has access to.
*/

/*
Problem Statement 1:
The website manager asks to pull data about most-viewed website pages, ranked by session volume.
She places the request on 09 Jun 2012.
*/

# Solution 1:
SELECT pageview_url, COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY 2 DESC;

/*
/home is receiving highest session volume, till 09 Jun 2012.
*/

/*
Problem Statement 2:
The website manager asks to pull a list of the top entry pages on the website, and rank them on entry volume.
She places the request on 12 Jun 2012.
*/

# Solution 2:
-- For every session, the landing page first needs to be identified.
CREATE TEMPORARY TABLE landing_page_by_session
SELECT 
	DISTINCT website_session_id, 
    MIN(website_pageview_id) AS landing_pageview_id -- The minimum will also pull the 1st page viewed for that session (since it's sorted by created_at) 
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY 1
;

/*
Temporary tables are helpful in breaking down a complex query into simpler steps, and they can help avoid recomputation.
*/

SELECT 
	 wp.pageview_url AS landing_page,
    COUNT(DISTINCT lps.website_session_id) AS sessions_hitting_this_landing_page
FROM landing_page_by_session lps
LEFT JOIN website_pageviews wp
	ON wp.website_pageview_id = lps.landing_pageview_id
GROUP BY 1
ORDER BY 2 DESC;

/*
At this point in the business, all sessions are landing on the home page.
*/

/*
Problem Statement 3:
The website manager asks to pull the total session volume, bounced sessions, and bounce rate for the existing homepage, 
where the homepage is acting as the landing page for each session.
She places the request on 14 Jun 2012.
*/

# Solution 3:

-- Firstly, a temp table is created that stores 'landing page id' for each relevant session
CREATE TEMPORARY TABLE pageviews_by_session
SELECT 
	DISTINCT website_session_id,
    MIN(website_pageview_id) AS landing_pg_id, -- provides pageview id of the landing page, for each session
	COUNT(DISTINCT website_pageview_id) AS pgs_viewed,  -- how many pages were viewed in that session
    CASE 
		WHEN COUNT(DISTINCT website_pageview_id) > 1 THEN 'non-bounced' ELSE 'bounced' END AS 'bounce_status' -- records the bounce status
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1
;

/* Secondly, LEFT JOIN is used to retrieve landing page url. 
Then, grouping by url to retrieve total sessions (where that url was landing page).
CASE statements are used to calculate bounce_rate
*/ 
SELECT 
	wp.pageview_url as landing_pg_url,
    -- pgs.website_session_id,
    -- pgs.landing_pg_id,
    -- pgs.bounce_status
    COUNT(DISTINCT pgs.website_session_id) AS total_sessions,
    SUM(CASE WHEN bounce_status = 'bounced' THEN 1 ELSE 0 END) AS bounced_sessions, -- will only add 'bounced' sessions, per url
    (SUM(CASE WHEN bounce_status = 'bounced' THEN 1 ELSE 0 END)/COUNT(DISTINCT pgs.website_session_id))*100 AS bounce_rate_perc -- dividing the above two columns
FROM pageviews_by_session pgs
LEFT JOIN website_pageviews wp
	ON pgs.landing_pg_id = wp.website_pageview_id
GROUP BY 1
; -- So landing page for all sessions is still '/home' only, with a bounce rate of 59.2%

/*
The website manager finds a bounce rate of about 60% to be pretty high, especially for a paid search channel that is expected to carry high quality traffic.
She suggests setting up a new custom landing page for paid search traffic to hopefully reduce the bounce rate.
*/

/*
Problem Statement 4:
The website manager asks to perform a A/B test after a custom lander page i.e. /lander-1 is launched 
on the website specifically for the gsearch nonbrand traffic. We are supposed to pull bounce rates for the two groups
for a proper performance evaluation.
The request is placed by the website manager on 28 July 2012.
*/

# Solution 4:

-- To set up the experiment, we first need to find out the launch date of the new lander page
SELECT *
FROM website_pageviews
WHERE pageview_url = '/lander-1'
ORDER BY created_at
LIMIT 10; -- The /lander-1 page was deployed on 19-06-2012

-- The website sessions must be filtered for specific gsearch nonbrand traffic to make A/B test fair
CREATE TEMPORARY TABLE relevant_sessions
SELECT * FROM website_sessions
WHERE 
	utm_source='gsearch' AND 
    utm_campaign='nonbrand' AND
    created_at > '2012-06-19' AND
    created_at < '2012-07-28';

-- Firstly, a temp table is created that stores 'landing page id' for each relevant session
-- a JOIN is included so that only relevant website sessions are considered
CREATE TEMPORARY TABLE pageviews_by_session_2
SELECT 
	DISTINCT wp.website_session_id,
    MIN(wp.website_pageview_id) AS landing_pg_id, -- provides pageview id of the landing page, for each session
    COUNT(DISTINCT wp.website_pageview_id) AS pgs_viewed,  -- how many pages were viewed in that session
    CASE 
		WHEN COUNT(DISTINCT wp.website_pageview_id) > 1 THEN 'non-bounced'
        WHEN COUNT(DISTINCT wp.website_pageview_id) = 1 THEN 'bounced' 
        ELSE NULL 	
	END AS 'bounce_status' -- records the bounce status
FROM website_pageviews wp
JOIN relevant_sessions rs
	ON rs.website_session_id = wp.website_session_id
GROUP BY 1
;

/* Secondly, LEFT JOIN is used to retrieve landing page url. 
Then, grouping by url to retrieve total sessions (where that url was landing page).
CASE statements are used to calculate bounce_rate
*/ 
SELECT 
	wp.pageview_url as landing_pg_url,
	-- pgs2.website_session_id,
	-- pgs2.landing_pg_id,
    -- pgs2.bounce_status
    COUNT(DISTINCT pgs2.website_session_id) AS total_sessions,
	SUM(CASE WHEN bounce_status = 'bounced' THEN 1 ELSE 0 END) AS bounced_sessions, -- will only add 'bounced' sessions, per url
	(SUM(CASE WHEN bounce_status = 'bounced' THEN 1 ELSE 0 END)/COUNT(DISTINCT pgs2.website_session_id))*100 AS bounce_rate_perc -- dividing the above two columns
FROM pageviews_by_session_2 pgs2
LEFT JOIN website_pageviews wp
	ON pgs2.landing_pg_id = wp.website_pageview_id
GROUP BY 1
	HAVING landing_pg_url IN ('/home', '/lander-1')
;

/* 
It appears that bounce rate is actually lower for /lander-1 page compared to /home page (53.2% v. 58.3%), according to the conducted A/B test.
*/

/*
Problem Statement 5:
The website manager places a request on 31 Aug 2012 to pull the volume of paid search nonbrand traffic 
landing on /home and /lander-1, trended weekly since June 1st. She also wants to pull the overall paid search bounce rate 
trended weekly.
*/

# Solution 5:
-- Step 1; filtering relevant sessions
CREATE TEMPORARY TABLE relevant_sessions_2
SELECT * FROM website_sessions
WHERE 
	utm_source='gsearch' AND 
    utm_campaign='nonbrand' AND
    created_at > '2012-06-01' AND
    created_at < '2012-08-31';

-- Step 2; joining website_pageviews table with filtered sessions from website_sessions table
CREATE TEMPORARY TABLE ld_pg_id_by_session 
SELECT 
	DISTINCT wp.website_session_id,
	MIN(wp.website_pageview_id) AS landing_page_id,
    MIN(wp.created_at) AS landing_page_created_at
FROM website_pageviews wp
JOIN relevant_sessions_2 rs2
	ON rs2.website_session_id = wp.website_session_id
GROUP BY 1
;

-- Step 3; adding landing page information by joining with website_pageviews table
CREATE TEMPORARY TABLE ld_pg_info_by_session 
SELECT 
	lps.website_session_id,
    lps.landing_page_id,
    lps.landing_page_created_at,
    wp.pageview_url AS land_pg_url
FROM ld_pg_id_by_session lps
LEFT JOIN website_pageviews wp
 ON lps.landing_page_id = wp.website_pageview_id
 ;
 
 -- Step 4; retrieving bounce status per relevant session
 CREATE TEMPORARY TABLE ld_pg_info_and_bounce_status_by_session 
 SELECT 
	lpi.website_session_id,
    lpi.landing_page_id,
    lpi.landing_page_created_at,
    lpi.land_pg_url,
    COUNT(DISTINCT wp.website_pageview_id) AS pgs_viewed,
    CASE
		WHEN COUNT(DISTINCT wp.website_pageview_id) = 1 THEN 'bounced'
        WHEN COUNT(DISTINCT wp.website_pageview_id) > 1 THEN 'non-bounced'
        ELSE NULL
	END AS bounce_status
FROM ld_pg_info_by_session lpi
LEFT JOIN website_pageviews wp
 ON lpi.website_session_id = wp.website_session_id
WHERE lpi.land_pg_url IN ('/home', '/lander-1')
 GROUP BY 1,2,3,4
 ;
 
  -- Step 5; creating trend analysis using CASE statements from the 'ld_pg_info_and_bounce_status_by_session' temporary table
SELECT 
	-- YEAR(landing_page_created_at) AS year_,
    -- WEEK(landing_page_created_at) AS week_num,
    MIN(DATE(landing_page_created_at)) AS week_start_date,
    SUM(CASE WHEN land_pg_url = '/home' THEN 1 ELSE 0 END) AS 'home_sessions',
    SUM(CASE WHEN land_pg_url = '/lander-1' THEN 1 ELSE 0 END) AS 'lander_sessions',
    (SUM(CASE WHEN bounce_status = 'bounced' THEN 1 ELSE 0 END)/COUNT(website_session_id))*100 AS overall_bounce_rt
FROM ld_pg_info_and_bounce_status_by_session 
GROUP BY 
	YEAR(landing_page_created_at),
    WEEK(landing_page_created_at)
ORDER BY week_start_date
; 

/*
The trend analysis does show that the traffic has been successfully routed from home page to lander-1.
The overall bounce rate has also dropped from roughly 60% to roughly 50%, after re-routing traffic.
*/

/*
Problem Statement 6:
The website manager would like to know where the business loses gsearch visitors between the new /lander-1 page and placing an order. 
In other words she needs a conversion funnel, showcasing how many customers make it to each step. 
Starting with /lander-1 we are supposed to build the funnel all the way to the thank you page. 
Data since August 5th has to be used. The request is placed by the manager on 05 Sep 2012.
*/

# Solution 6:
-- Firstly, relevant sessions are extracted and joined with website_pageview to retrieve URLs. Flags are added for each stage of the conversion funnel.
CREATE TEMPORARY TABLE sessions_with_pageview_flags
SELECT 
	wp.website_session_id, 
    website_pageview_id, 
    wp.created_at, wp.pageview_url, 
    CASE WHEN wp.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS 'lander_dumm',
    CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS 'products_dumm',
    CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS 'mr_fuzzy_dumm',
    CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS 'cart_dumm',
    CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS 'shipping_dumm',
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS 'billing_dumm',
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS 'ty_dumm'
FROM website_pageviews wp
JOIN(
		SELECT website_session_id 
		FROM website_sessions
		WHERE 
			utm_source = 'gsearch' AND
			utm_campaign = 'nonbrand' AND
			created_at BETWEEN '2012-08-06' AND '2012-09-04' 
	) rs
	ON wp.website_session_id = rs.website_session_id
;

-- Secondly, data from previous table is grouped by wesbite_session to see how a customer progresses through a conversion funnel
CREATE TEMPORARY TABLE sessions_with_pageview_progress
SELECT 
	website_session_id,
    CASE WHEN MAX(lander_dumm) = 1 THEN 1 ELSE 0 END AS lander_made_it,
    CASE WHEN MAX(products_dumm) = 1 THEN 1 ELSE 0 END AS products_made_it,
    CASE WHEN MAX(mr_fuzzy_dumm) = 1 THEN 1 ELSE 0 END AS mr_fuzzy_made_it,
    CASE WHEN MAX(cart_dumm) = 1 THEN 1 ELSE 0 END AS cart_made_it,
    CASE WHEN MAX(shipping_dumm) = 1 THEN 1 ELSE 0 END AS shipping_made_it,
    CASE WHEN MAX(billing_dumm) = 1 THEN 1 ELSE 0 END AS billing_made_it,
    CASE WHEN MAX(ty_dumm) = 1 THEN 1 ELSE 0 END AS ty_made_it
FROM sessions_with_pageview_flags
GROUP BY 1
;

-- Thirdly, flag dummies are aggregated for each step of the conversion funnel to see total sessions that made it to that step (in the funnel)
SELECT 
	SUM(lander_made_it) AS sessions,
    SUM(products_made_it) AS to_products,
    SUM(mr_fuzzy_made_it) AS to_mr_fuzzy,
	SUM(cart_made_it) AS to_cart,
	SUM(shipping_made_it) AS to_shipping,
    SUM(billing_made_it) AS to_billing,
    SUM(ty_made_it) AS to_ty
FROM sessions_with_pageview_progress;

-- Forth, calculating the clickthrough rate (CTR) for each stage of the funnel (as a proportion of sessions making it to the previous stage)
SELECT 
    SUM(products_made_it)/SUM(lander_made_it) AS lander_ctr,
    SUM(mr_fuzzy_made_it)/SUM(products_made_it) AS products_ctr,
	SUM(cart_made_it)/SUM(mr_fuzzy_made_it) AS mr_fuzzy_ctr,
	SUM(shipping_made_it)/SUM(cart_made_it) AS shipping_ctr,
    SUM(billing_made_it)/SUM(shipping_made_it) AS cart_ctr,
    SUM(ty_made_it)/SUM(billing_made_it) AS billing_ctr
FROM sessions_with_pageview_progress;

/*
Based on conversion funnel analysis, the clickthrough rate was found to be particularly low for 
lander_page, mr_fuzzy page, and billing page. The website manager now knows where to focus for improvements
and is proposing to test-out some new pages for these stages of the conversion funnel to hopefully improve the clickthrough rate
onto the next stage.
*/

/*
Problem Statement 7:
The website manager updated billing page and would like to see whether /billing-2 is doing any better than the original /billing page. 
In other words, she would like an A/B test to be conducted to evaluate what % of sessions on those pages end up 
placing an order (i.e. ctr of billing page). 
As a special note, the updated billing page was developed for the entire traffic, not just the gsearch nonbrand traffic.
The request is placed by the manager on 10 Nov 2012.
*/

# Solution 7:
-- It is good to know when the updated billing page was launched to set up the A/B experiment.
SELECT * FROM website_pageviews WHERE pageview_url = '/billing-2' ORDER BY created_at; -- launched at 10 Sep 2012.

-- creating flags for billing page shown and order placement page per session, based on relevant sessions
CREATE TEMPORARY TABLE billing_pg_flags_by_session
SELECT 
    wp.website_session_id,
    wp.website_pageview_id,
    wp.pageview_url,
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS is_billing,
    CASE WHEN wp.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS is_billing_2,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS ty_flag
FROM website_pageviews wp
JOIN(
	SELECT * FROM website_sessions WHERE created_at BETWEEN '2012-09-10' AND '2012-11-09' -- filtering the data
    ) rss ON
    wp.website_session_id = rss.website_session_id
WHERE wp.pageview_url IN ('/billing-2', '/billing', '/thank-you-for-your-order')
ORDER BY 1;

-- creating 3 seperate columns containing info on billing page shown and order status, per unique session_id
CREATE TEMPORARY TABLE bill_pg_and_order_status_by_unique_session
SELECT 
	website_session_id, 
    MAX(is_billing) AS billing_1_pg,
    MAX(is_billing_2) AS billing_2_pg,
    MAX(ty_flag) AS order_placed
FROM billing_pg_flags_by_session
GROUP BY 1;

-- agrregating to reveal total sessions and orders (by billing page shown to the customer)
SELECT 
	bill_pg_url,
    COUNT(website_session_id) AS sessions,
    SUM(order_placed) AS orders,
    SUM(order_placed)/COUNT(website_session_id) AS bill_to_order_rt
FROM(
	SELECT
	website_session_id,
		CASE 
			WHEN billing_1_pg = 1 THEN '/billing' 
			WHEN billing_2_pg = 1 THEN '/billing-2' 
			ELSE NULL
		END AS bill_pg_url,
	order_placed
	FROM bill_pg_and_order_status_by_unique_session
	) AS bpg
GROUP BY 1
;

/* 
It can be seen that /billing-2 page has considerably increased the click-through rate of billing page (from previous 45% to current 62%).
This means customers are more likely to place orders now, after arriving at the new billing page.
Hence, the A/B test conducted using ctr reveals that the /billing-2 page is a success and should be implemented in place of /billing. 
*/
