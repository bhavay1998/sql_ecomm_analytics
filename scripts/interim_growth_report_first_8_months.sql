USE mavenfuzzyfactory;

-- Intermediate Report for Board Meeting 
	# (requested on 27 November 2012) #
--------------------------------------------------

/*
Problem Statement 1:
Gsearch appears to be the biggest driver of the business. CEO would like to pull monthly trends for gsearch sessions and orders.
*/

# Solution 1:
SELECT 
	MIN(DATE(ws.created_at)) AS month_start,
    COUNT(DISTINCT ws.website_session_id) AS gs_sessions,
    COUNT(o.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders o
	ON o.website_session_id = ws.website_session_id
WHERE 	
	ws.utm_source = 'gsearch' AND
    ws.created_at < '2012-11-27'
GROUP BY 
	YEAR(ws.created_at),
    MONTH(ws.created_at)
ORDER BY 1
;

/* 
Monthly trend analysis, from march to november 2012, shows that Gsearch traffic and orders coming from this source have both increased with time. 
*/

/*
Problem Statement 2:
CEO would like to pull monthly trend for Gsearch, splitting out nonbrand and brand campaigns separately.
*/

# Solution 2:
SELECT 
	MIN(DATE(ws.created_at)) AS month_start,
    COUNT(CASE WHEN ws.utm_campaign='nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbr_sessions,
    COUNT(CASE WHEN ws.utm_campaign='nonbrand' THEN o.order_id ELSE NULL END) AS nonbr_orders,
    COUNT(CASE WHEN ws.utm_campaign='brand' THEN ws.website_session_id ELSE NULL END) AS br_sessions,
    COUNT(CASE WHEN ws.utm_campaign='brand' THEN o.order_id ELSE NULL END) AS br_orders
FROM website_sessions ws
LEFT JOIN orders o
	ON o.website_session_id = ws.website_session_id
WHERE 	
	ws.utm_source = 'gsearch' AND
    ws.created_at < '2012-11-27'
GROUP BY 
	YEAR(ws.created_at),
    MONTH(ws.created_at)
ORDER BY 1
;

/* 
Dissecting Gsearch source into two campaigns ('brand' and 'nonbrand'), we see that session volume 
has grown for both according to the monthly trend analysis. In particular, 'nonbrand' campaign is
carrying the majority of the session volume. Same pattern is observed by looking at the orders made from
each campaign. 

Since 'brand' sessions represent those sessions where a website visitor explicitly looks for the business from the search engine,
increase session volume and orders from this source represents the user interest for the eCommerce company is actually improving.
*/

/*
Problem Statement 3:
For Gsearch nonbrand, CEO would like to pull monthly sessions and orders split by device type.
*/

# Solution 3:
SELECT 
	MIN(DATE(ws.created_at)) AS month_start,
    COUNT(CASE WHEN ws.device_type='mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(CASE WHEN ws.device_type='desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(CASE WHEN ws.device_type='mobile' THEN o.order_id ELSE NULL END) AS mobile_orders,
	COUNT(CASE WHEN ws.device_type='desktop' THEN o.order_id ELSE NULL END) AS desktop_orders
FROM website_sessions ws
LEFT JOIN orders o
	ON o.website_session_id = ws.website_session_id
WHERE 	
	ws.utm_source = 'gsearch' AND
    ws.utm_campaign ='nonbrand' AND
    ws.created_at < '2012-11-27'
GROUP BY 
	YEAR(ws.created_at),
    MONTH(ws.created_at)
ORDER BY 1
;

/*
Desktop device type carries the majority of session volume and the orders resulting from gsearch nonbrand campaign.
The monthly trend analysis (from march to november 2012) reveals that both session volume and order volume have increased.
The bid was increased only for 'desktop', but it's interesting to see that 'mobile' sessions and the
orders arising from those sessions have also increased in the trend analysis.
*/

/*
Problem Statement 4:
CEO would like to pull monthly trends for Gsearch, alongside monthly trends for each of the other channels.
*/

# Solution 4:
-- how many total channels are present?
SELECT DISTINCT utm_source FROM website_sessions WHERE created_at < '2012-11-27';

-- weekly trend by channel
SELECT 
	MIN(DATE(ws.created_at)) AS month_start,
    COUNT(CASE WHEN ws.utm_source='gsearch' THEN ws.website_session_id ELSE NULL END) AS gsrch_sessions,
    COUNT(CASE WHEN ws.utm_source='bsearch' THEN ws.website_session_id ELSE NULL END) AS bsrch_sessions,
    COUNT(CASE WHEN ws.utm_source IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_src_sessions
FROM website_sessions ws
WHERE 	
    ws.created_at < '2012-11-27'
GROUP BY 
	YEAR(ws.created_at),
    MONTH(ws.created_at)
ORDER BY 1
;

/*
The monthly trend analysis (from march to november 2012), reveals that gsearch sessions carry the most volume of sessions,
followed by bsearch followed by 'direct-source' sessions. The session volume for every channel has increased with time. 
What is interesting here is, direct-source sessions represent those sessions fow which the business didn't pay anything out of its marketing budget.
The growth of this channel means that the business is now gaining awareness in its ability to attract users organically, 
instead of completly relying on paid channels. 
*/

/*
Problem Statement 5:
CEO would like to pull session to order conversion rates, by month.
*/

# Solution 5:
SELECT 
	MIN(DATE(ws.created_at)) AS month_start,
    COUNT(ws.website_session_id) AS sessions,
	COUNT(o.order_id) AS orders,
    COUNT(o.order_id)/COUNT(ws.website_session_id) AS conversion_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON o.website_session_id = ws.website_session_id
WHERE 	
    ws.created_at < '2012-11-27'
GROUP BY 
	YEAR(ws.created_at),
    MONTH(ws.created_at)
ORDER BY 1
;

/*
The monthly trend analysis shows that for the first 8 months of the business, 
the sesstion-to-order conversion rate in Nov 2012 has grown by 38% (with respect to CVR in Mar 2012).
Both session volume and order volume has improved (578% and 835% respectively, with respect Mar 2012 values).
*/

/*
Problem Statement 6: 
For the landing page test analyzed previously, show a full conversion funnel from each of the two pages to orders. 
The same time period you analyzed last time (Jun 19 – Jul 28) is to be used.
*/

# Solution 6:
-- creating flags for each pageview, per relevant website_session
CREATE TEMPORARY TABLE page_flags_by_session
SELECT 
	wp.website_pageview_id,
    wp.created_at,
    wp.website_session_id,
    wp.pageview_url,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS is_products,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mr_fuzzy,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS is_cart,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS is_shipping,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS is_billing,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS is_ty_pg,
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS is_home,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS is_lander_1
FROM website_pageviews wp
INNER JOIN(
	SELECT * FROM website_sessions
	WHERE 
		created_at BETWEEN '2012-06-19' AND '2012-07-28' AND
		utm_source = 'gsearch' AND
		utm_campaign = 'nonbrand'
    ) AS rs ON rs.website_session_id = wp.website_session_id
;   

-- consolidating the entry page flags into a single column, so that GROUP BY could be used to generate separate conversion flows
CREATE TEMPORARY TABLE cov_funnel_unagg
SELECT 
		website_session_id,
		CASE
			WHEN home_entry = 1 THEN '/home'
            WHEN lander_1_entry = 1 THEN '/lander-1'
            ELSE NULL END AS entry_pg_url,
		products_made_it,
		mr_fuzzy_made_it,
		cart_made_it,
		shipping_made_it,
		billing_made_it,
		thank_you_made_it 
FROM (    
		SELECT 
			website_session_id,
			MAX(is_home) AS home_entry,
			MAX(is_lander_1) AS lander_1_entry,
			MAX(is_products) AS products_made_it,
			MAX(mr_fuzzy) AS mr_fuzzy_made_it,
			MAX(is_cart) AS cart_made_it,
			MAX(is_shipping) AS shipping_made_it,
			MAX(is_billing) AS billing_made_it,
			MAX(is_ty_pg) AS thank_you_made_it   
		FROM page_flags_by_session
		GROUP BY 1
        ) AS conversion_flow; -- subquery table calculates whether each step of the conversion funnel took place or not, for unique session;
 
 -- conversion flow achieved by aggregating cov_funnel_unagg, grouped by entry page
SELECT 
	entry_pg_url,
    COUNT(website_session_id) AS landing_sessions,
	SUM(products_made_it) AS products_sessions,
	SUM(mr_fuzzy_made_it) AS mr_fuzzy_sessions,
	SUM(cart_made_it) AS cart_sessions,
	SUM(shipping_made_it) AS shipping_sessions,
	SUM(billing_made_it) AS billing_sessions,
	SUM(thank_you_made_it) AS thank_you_sessions
FROM cov_funnel_unagg
GROUP BY 1;

-- Clickthrough rate, at each step of the funnel
SELECT 
	entry_pg_url,
	SUM(products_made_it)/COUNT(website_session_id) AS entry_pg_ctr,
	SUM(mr_fuzzy_made_it)/SUM(products_made_it) AS products_ctr,
	SUM(cart_made_it)/SUM(mr_fuzzy_made_it) AS mr_fuzzy_ctr,
	SUM(shipping_made_it)/SUM(cart_made_it) AS cart_ctr,
	SUM(billing_made_it)/SUM(shipping_made_it) AS shipping_ctr,
	SUM(thank_you_made_it)/SUM(billing_made_it) AS billing_ctr
FROM cov_funnel_unagg
GROUP BY 1;

/*
Conversion funnel (comprising 7 steps/page sequence), bifurcated by the entry pages used in the A/B test (Jun 19 – Jul 28), is generated.
'/lander-1' has 5% better entry-page clickthrough rate compared to '/home' page, as seen in the funnel.
*/