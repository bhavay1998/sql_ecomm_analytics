# SQL: Ecommerce and Web Analytics
This project is based on the <mark>Udemy course by John Pauler</mark> - <i>[Advanced SQL: MySQL for Ecommerce & Web Analytics](https://www.udemy.com/course/advanced-sql-mysql-for-analytics-business-intelligence/)</i>. <br>
The project assumes the role of a <mark>eCommerce database analyst</mark> for a <mark>newly launched eCommerce startup</mark> named `Maven Fuzzy Factory`. The project's primary focus is not only to develop advanced SQL queries, but to thoroughly emphasise the <mark>business logic</mark> and <mark>decision support</mark> behind it. 

## About the Database
The project is based on a highly comprehensive eCommerce database built from scratch by [John Pauler](https://www.linkedin.com/in/johnpauler/), member of the [Maven Analytics](https://mavenanalytics.io/) team. Instead of working on random samples of data, the database is designed to <mark>closely mimic real-word databases specific to eCommerce startups</mark> and internet retailers that heavily rely on online stores to generate sales. The database is created using the [create_mavenfuzzyfactory_db.sql](https://github.com/bhavay1998/sql_ecomm_analytics/blob/main/scripts/init_database/create_mavenfuzzyfactory_db.sql) file. 

### Database Schema
<p align="center">
  <img src="database_schema.png" alt="Schema Diagram" width="600"/>
</p>
<br><br>

The database contains six related tables:
- `orders` - contains purchase orders placed by customers; order might contain multiple items
- `order_items` - can be linked to the <i>orders</i> table to get information about the number of items contained within a particular order
- `products` - can be linked with <i>order_items</i> to get product level information for a placed order
- `order_item_refunds` - can be linked to the <i>orders</i> table to get information about refunds made on orders with customer complaints
- `website_sessions` - helps identify the source of website traffic (via <mark>utm and related parameters</mark>) through which orders are being generated
- `website_pageviews` - contains information on pages of a website visited by a user; for a specific website session 

## Objective
The aim of the project is to help the management (i.e. CEO, Marketing Director and Website Manager) grow the eCommerce business and understand how to improve performance. Analysis is performed to optimize the business’ marketing channels, website, and product portfolio. All analyses are performed using the `MavenFuzzyFactory` database on MySQL Workbench.
The project is intended to perform BI analysis by querying the database, instead of working on database warehousing, building and maintenance. 

## Project Highlights
The highlights mentioned for each section of the project can be verified by looking at the [output tables](scripts_output).
### Traffic Source Analysis

Assisted the Marketing Director in optimizing paid marketing channels using SQL-based traffic source analysis:
- Analyzed UTM parameters to identify primary sources of website traffic, finding `gsearch non-brand` as the dominant paid channel.
- Evaluated conversion rates against a `4% CVR benchmark` to reveal that the paid traffic bids were not justified.
- Performed weekly trend analysis to measure changes in paid traffic volume following bid adjustments.
- Identified a significant CVR gap between `desktop` and `mobile` users (3.73% v. 0.97% resp.), leading to increased bids on `desktop traffic`.
- Post-optimization, `desktop sessions` and `overall paid traffic` volume increased over time, shown via weekly trend analysis.

### Website Content and Conversion Funnel Analysis
Analyzed on-site user behavior and conversion performance to identify content bottlenecks and optimize the purchase journey:

- Ranked most-viewed website pages by session volume to understand how users interact with site content, identifying `/home` as the dominant entry page.
- Calculated homepage bounce rate (~60%) by isolating landing-page sessions, highlighting poor engagement for paid search traffic.
- Designed an A/B test for a new paid-search landing page `/lander-1`, showing a lower bounce rate for `/lander-1` vs. `/home`.
- Conducted weekly trend analysis to track traffic re-routing from `/home` to `/lander-1`, demonstrating a drop in overall bounce rate from ~60% to ~50%.
- Built a full conversion funnel from landing page to order confirmation, quantifying user drop-off at each step of the purchase journey.
- Identified key funnel leakage points (`/lander-1`, `/products`, and `/billing` pages) using step-level click-through rates.
- Performed an A/B test on billing page redesign (`/billing` vs `/billing-2`), showing a significant lift in billing-to-order conversion (≈45% → 62%).

### Interim Growth Report
Analyzed how the business is doing in the first 8 months of its operations, to help the CEO prepare for the board meeting:
- `gsearch` sessions and orders increased steadily month over month, confirming it as the primary growth channel.
- `nonbrand` campaigns account for the majority of `gsearch` session and order volume, while `brand` traffic also shows consistent growth.
- Rising `brand` driven sessions and orders indicate increasing user awareness and intent.
- `desktop` traffic generates most sessions and orders, but `mobile` sessions and orders also increased over time despite bid increases applied only to `desktop`.
- Gsearch produces the highest session volume, followed by bsearch and then direct traffic; all channels show sustained growth.
- Growth in direct-source sessions indicates increasing organic brand recognition where business isn't relying on paid channels.
- Session to order conversion rate in Nov 2012 is 38% higher than in Mar 2012, alongside 578% session growth and 835% order growth.
- `/lander-1` outperforms `/home` with a 5% higher entry-page clickthrough rate across the full conversion funnel.
