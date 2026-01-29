# Ecommerce and Web Analytics
This project is based on the <mark>Udemy course by John Pauler</mark> - <i>[Advanced SQL: MySQL for Ecommerce & Web Analytics](https://www.udemy.com/course/advanced-sql-mysql-for-analytics-business-intelligence/)</i>. <br>
The project assumes the role of a `eCommerce database analyst` for a <mark>newly launched eCommerce startup</mark> named `Maven Fuzzy Factory`. The project's primary focus is not only to develop advanced SQL queries, but to thoroughly emphasise the `business logic` behind it. 

## About the Database
The project is based on a highly comprehensive eCommerce database built from scratch by [John Pauler](https://www.linkedin.com/in/johnpauler/), member of the [Maven Analytics](https://mavenanalytics.io/) team. Instead of working on random samples of data, the database is designed to <mark>closely mimic real-word databases specific to eCommerce startups</mark> and internet retailers that heavily rely on online stores to generate sales. The database is created using [create_mavenfuzzyfactory_db.sql](https://github.com/bhavay1998/sql_ecomm_analytics/blob/main/create_mavenfuzzyfactory_db.sql) file. The database contains six related tables:
- <mark>orders</mark> - contains purchase orders placed by customers; order might contain multiple items
- <mark>order_items</mark> - can be linked to the <i>orders</i> table to get information about the number of items contained within a particular order
- <mark>products</mark> - can be linked with <i>order_items</i> to get product level information for a placed order
- <mark>order_item_refunds</mark> - can be linked to the <i>orders</i> table to get information about refunds made on orders with customer complaints
- <mark>website_sessions</mark> - helps identify the source of website traffic (via `utm` and related parameters) through which orders are being generated

![Schema Diagram](scripts/Schema_Maven_Fuzzy_Factory.png)

## Objective
The aim of the project is to help the management (i.e. CEO, Marketing Director and Website Manager) grow the business and understand how to improve performance. Analysis is performed to optimize the business’ marketing channels, website, and product portfolio. All analyses are performed by querying the eCommerce database using MySQL Workbench.
The project is intended to perform BI analysis by querying the database, instead of focusing on data building and maintenance. 

## Database Schema
The schema is stored in the project repository. It can also be visited with the link: <u> https://github.com/bhavay1998/Web_Analytics/blob/main/Schema.pdf </u>

## Project Highlights
The project begins with assisting the Marketing Director in optimising marketing channels through Traffic Source Analysis & Bid Optimization. Result:
- Marketing spent is justified for 'gsearch nonbrand' campaign, only for 'desktop' device
- Conversion Rate and Session Volume are the metrics used for this justification

The project concludes with assisting the Website Manager in website content analysis and A/B testing for landing page analysis. Result:
- Recommended a custom lander page since the bounce rate for the default lander page was unreasonably high (~60%)
- In an A/B test, custom lander performed better than the default lander (bounce rate ~53%)
- In a trend analysis, the business witnessed a reduction in the overall bounce rate for their website

## Project Code
The two code files *Traffic Source Analysis* and *Website Measurement & Testing* are present both in **PDF** and **Jupyter Notebook** formats in the project repository. The code was run on Jupyer Notebooks with MySQL client to make code output visible directly under the code cell. This makes the code easy to interpret.
Links:
- https://github.com/bhavay1998/Web_Analytics/blob/main/Traffic%20Source%20Analysis.ipynb
- https://github.com/bhavay1998/Web_Analytics/blob/main/Website%20Content%20Analysis%20and%20Testing.ipynb
