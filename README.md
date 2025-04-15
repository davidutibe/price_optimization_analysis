# Project: Optimizing Pricing and Promotions for Profitability in Grocery Retail

## Table of Content

1. [Introduction](#introduction)
2. [Project Description](#project-description)
3. [Research Questions](#research-questions)
4. [About the Dataset](#about-the-dataset)
5. [Languages, Utilities, and Environments Used](#languages-utilities-and-environments-used)
6. [Importing the Dataset into Microsoft SQL Server](#importing-the-dataset-into-microsoft-sql-server)
7. [Data Automation: Cleaning and Transformation](#data-automation-cleaning-and-transformation)
   - [Renamed Columns](#renamed-columns)
   - [Changed Column Data Types](#changed-column-data-types)
8. [Data Analysis using SQL generated queries](#data-analysis-using-sql-generated-queries)
   - [Top 5 Margins](#1-top-5-margins)
   - [Promo Uplift](#2-promo-uplift)
   - [Average Order Volume (AOV)](#3-average-order-volume-aov)
   - [Attach Rate](#4-attach-rate)
   - [Customer Lifetime Segmentation (CLV)](#5-customer-lifetime-segmentation-clv)
   - [Bundle Performance](#6-bundle-performance)
9. [Insights from the Data Analysis](#insights-from-the-data-analysis)
10. [Recommendations from the Data Analysis](#recommendations-from-the-data-analysis)
11. [Conclusion](#conclusion)
12. [Glossary of Terms](#glossary-of-terms)


## Introduction
Home Store (hypthetical), is a growing grocery delivery service across Nigeria, faced with tightening gross margins and a slowdown in repeat purchases. Leadership suspected that blanket discounting strategies were undercutting profitability and sought a more data-driven approach to pricing, bundling, and promotions.

Using SQL, I analyzed their sales and customer data to identify patterns in margin contribution, customer behavior, and bundle effectiveness—leading to clear, actionable recommendations.

## Project Description
The project involves the analysis of the Home Store Sales and Customer behaviour Data. The tasks to be completed include:
1. Explore the data to look for the greatest correlations between the various bundles, promo strategies and profitability.
2. Explore the data to determine the most profitable SKUs and cities with the most valuable customers.
3. Create a markdown file for deployment.
4. Host the code on GitHub or GitLab.


## Research Questions
The project aims to answer the following research questions:
1. Which SKUs deliver the highest gross margins?
2. How do discount vs volume deal promotions impact promo uplift?
3. Which promotion type results in higher AOV (Average Order Value)?
4. Which products drive the most add-on purchases (attach rate)?
5. How does Customer Lifetime Value (CLV) vary across cities?
6. Which bundles strike the best tradeoff between profit margin and customer perception?

## About the Dataset
The dataset was randomly simulated using microsoft excel. It contains 1800 entries, each entry representing a sales transaction with a unique transaction id. 
[(Link to the dataset)](https://docs.google.com/spreadsheets/d/1i778j9FUP08VgS25v64mK8oGUDGDGCxYe9vUziXigrg/edit?gid=0#gid=0)

The dataset 1800 rows 15 columns with SKU transaction information. The columns are described as follows:
* *TransactionID*: A unique ID assigned to each transaction
* *CustomerID*: A unique Identifier for each customer that transacted
* *SignupDate*: Date the customer was signed up on the platform
* *City*: City the transaction was carried out
* *ProductID*: A unique identifier for each SKU purchased
* *ProductCategory*: A general classification for similar SKU grouping
* *ProductName*: Name of SKU
* *Quantity*: Total SKU units purchased per SKU transaction
* *CostPrice*: Price the SKU was purchased at
* *UnitPrice*: Selling price of the SKU
* *DiscountPercent*: Agreed discount per SKU purchase
* *PromoApplied*: True/ False Validation to indicate if the transaction was a promo sale or baseline sale
* *PromoType*: Indicator of the type of promo applied
* *AttachRate*: A numeric indicator indicating the rate at which an SKU was purchased with other SKUs
* *TransactionDate*: Date the transaction occurred

## Languages, Utilities, and Environments Used
* Microsoft Excel: Data Simulation
* SQL: Data transformation, Analysis, and Exploration [(link to the SQL analysis file)] ()
* Environment: Microsoft SQL Server Management Studio

## Importing the Dataset into Microsoft SQL Server
To import the dataset to the SQL Server database, I proceeded as follows:  
* Launched the Microsoft SQL Management Studio
* Navigated to the database > selected Tasks > selected Import flat file
* In the new window that appears, I clicked on Next
* Used the drop-down menu and selected Flat File Source > Next
* Clicked on Browse > selected the file from my computer > Open
* Validated column properties such as primary key, data type, allow nulls 
The above steps successfully imported the dataset into my database in SQL Server.

## Data Automation: Cleaning and Transformation

### Renamed Columns
To rename columns for consistency, the queries below were executed.
* Renamed the CostPrice column to maintain uniformity with the naming convention of other columns 
```
EXEC sp_rename 'Pricing_Dataset.Cost_Price', 'CostPrice', 'COLUMN';
```

### Changed Column Data Types 
To ensure that columns that will be used for calculations were of the right data type to handle calculations, I applied the following modifications:
```
alter table Pricing_Dataset
alter column UnitPrice int;
alter table Pricing_Dataset
alter column CostPrice int;
alter table Pricing_Dataset
alter column ProductID Decimal;
``` 
**Output**: 3 columns data types were updated accordingly.

## Data Analysis using SQL generated queries

1. **Top 5 Margins**
* SKUs with the top 5 gross margins: this will help in determining the most profitable SKUs. 
 
```
WITH margin_calculation AS (
    SELECT 
        ProductID,
        ProductName,
        (UnitPrice * (1 - DiscountPercent)) * Quantity AS Revenue,
        CostPrice * Quantity AS COGS
    FROM dbo.Pricing_Dataset
)
SELECT 
    ProductID,
    ProductName,
    ROUND(AVG((Revenue - COGS) / Revenue), 2) AS Gross_Margin_Percent
FROM margin_calculation
WHERE ProductID IS NOT NULL
GROUP BY ProductID, ProductName
ORDER BY Gross_Margin_Percent DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
```

2. **Promo Uplift**
* Comparing the performance in Revenue between the different promo types to the baseline sales to determine promo uplift. This will help in determing how each promo type affected revenue compared to sales without any promos applied.

```
with baseline_revenue as (
	select
		SUM((UnitPrice * (1 - DiscountPercent)) * Quantity) as baseline_rev
	from 
		Pricing_Dataset
	where
		PromoApplied = 'FALSE'
		),
promo_revenue as (
	select 
		PromoType,
		sum((UnitPrice * (1 - DiscountPercent)) * Quantity) as revenue_promo
	from 
		dbo.Pricing_Dataset
	where 
		PromoType in ('Discount','Volume Deal')
	group by
		PromoType
		)
select
	PromoType,
	round((revenue_promo-baseline_rev)/baseline_rev,2) as PromoUplift
from 
	baseline_revenue, promo_revenue;
```

3. **Average Order Volume (AOV)**
* Determining which promo type drove the highest average order volume. This will help in determining which SKUs is driving revenue in terms of return purchases i.e. frequency.
```
select 
	PromoType, 
	SUM(((UnitPrice * (1 - DiscountPercent)) * Quantity))/
	COUNT(DISTINCT TransactionID) AS AOV
from
	dbo.Pricing_Dataset
where 
	PromoType in ('Discount','Volume Deal')
group by
	PromoType;
```

4. **Attach Rate**
* Determining which products have the highest attach rate - this will help in determining which products drive the most add-on i.e. products that are frequently purchased with other SKUs.

```
select 
	ProductID,
	ProductName,
	Avg(AttachRate) as attach_rate
from 
	dbo.Pricing_Dataset
where
	ProductID is not null
group by
	ProductID, ProductName
order by Avg(AttachRate) desc;
```

5. **Customer Lifetime Segmentation (CLV)**
* Determining the CLV by City - this will help in assesing which city is top performing in terms of the total worth of customer since acquisition

```
WITH CLV_calculation AS (
    SELECT 
        City,
        CustomerID, 
        DATEDIFF(MONTH, MIN(SignupDate), MAX(TransactionDate)) AS Customer_lifespan,
        COUNT(DISTINCT TransactionID) AS Purchase_Frequency,
        SUM((UnitPrice * (1 - DiscountPercent)) * Quantity) / COUNT(DISTINCT TransactionID) AS Avg_Revenue
    FROM 
        Pricing_Dataset
    GROUP BY
        City,
        CustomerID
),
CLV_per_customer AS (
    SELECT 
        City,
        (Avg_Revenue * Purchase_Frequency * Customer_lifespan) AS Customer_CLV,
		COUNT(distinct CustomerID) as total_customers
    FROM 
        CLV_calculation
	group by City, (Avg_Revenue * Purchase_Frequency * Customer_lifespan)
)
SELECT 
    City,
    SUM(Customer_CLV) / sum(total_customers) AS CLV_per_City
FROM 
    CLV_per_customer
GROUP BY 
    City
ORDER BY 
    CLV_per_City DESC;
```

6. **Bundle Performance**
* Determining which bundles are top performing in terms of margins and perception trade-off

```
select 
	ProductName as Bundle,
	round(sum(((UnitPrice * (1 - DiscountPercent)) * Quantity)- CostPrice*Quantity)
		/ sum(((UnitPrice * (1 - DiscountPercent)) * Quantity)),4) as Gross_Margin_percent,
	count(distinct TransactionID) as number_of_orders,
	round(avg(AttachRate),2) as AttachRate
from 
	dbo.Pricing_Dataset
where 
	ProductCategory is null
group by
	ProductName
order by
	Gross_Margin_percent desc, 
	number_of_orders desc,
	AttachRate desc;
```
 
## Insights from the Data Analysis
1. **Top 5 Performing SKUs by Gross Margin**  
   * *Observation*: Rice (5Kg) and Cooking Oil generated the highest profit margin with 81% and 57% respectively. The remaining 3 SKUs - Soft Drink (29%), Milk (28%), and Pasta (28%) cluster closely with modest margins, significantly low compared to the top 2. 
   * *Insights*: The top two SKUs (Rice and Cooking Oil) significantly outperformed the others. This suggests highly profitable items and could be prioritized in sales strategies, promotions, or bundling. The low performance of the other 3 SKUs could indicate commodity pricing pressures or higher cost structures

2. **Promo Uplift - Discount Vs Volume Deals**  
   * *Observation*:
     * Volume Deal promotions show a positive uplift of +63%, while discount promotion show a negative uplift of -41%.
   * *Insights*: The high promo uplift value for volume deals indicate they are effective at increasing sales or purchase quantities, and suggests that customers are responding well to offers that reward bulk buying. On the other hand, the extremely low value of discount deals indicate they may be hurting performance — possibly by eroding perceived value or not driving sufficient volume to compensate for the price drop.

3. **Which Promo resulted in higher AOV?**  
   * *Observation*:
     * Volume Deals generate a significantly higher AOV of ₦65,186, compared to just ₦25,937 for Discount promotions.
     * This means that customers who engage with Volume Deal promos spend ~151% more per order than those responding to Discount promos.
   * *Insights*: 
        * Volume-based incentives are not only driving higher sales (as seen in the promo uplift data) but also contributing to larger basket sizes.
        * Discounts, while common, are leading to lower average revenue per order, which may hurt profitability — especially if the uplift is also negative.

4. **Which Products Drive the Most Add-Ons?**  
   * *Observation*:
     * Top 3 Products with highest attach rate - Beer (41.4%), Pasta (41.1%), Noodles (40.7%).
     * Mid Performers: Rice (40.5%), Seasoning (40.3%), Tomato Paste (40.1%).
     * Low Performers: Eggs (39.7%), Milk (39.4%), Cooking Oil (39.2%), Soft Drink (38.1%)
   * *Insights*: The top 3 performers have the highest attach rates, meaning they are most effective at driving add-on purchases. The mid performing products also encourage add-on purchases but not as strongly as the top 3.

5. **Which Cities have the highest Customer Lifetime Value?**  
   * *Observation*: Customers in Abuja are the most valuable customers with ₦3.33 million in CLV. Port Harcourt and Lagos follow closely with ₦3.05 million and ₦2.98 million respectively, while Ibadan lags closely behind at ₦2.83 million — still substantial, but lower than the others.
    * *Insights*: 
        * The high CLV in Abuja suggests This suggests higher spending, stronger loyalty, or longer customer relationships.
        * Port Harcourt and Lagos though behind Abuja are still key markets with high potential for revenue growth.
        * The lower CLV in Ibadan may indicate room to improve retention or increase purchase frequency/value.
6. **Which Bundles Give the Best Margin vs Perception Tradeoff?**  
   * *Observation*:  
     * **Party Pack**: Highest attach rate (41%), strong gross margin (11.4%), high number of orders (63)  
     * **Naija Jollof Combo**: Strong attach rate (40%), good margin (11.39%), 58 orders  
     * **Breakfast Starter**: Strong attach rate (40%), good margin (11.27%), 58 orders  
     * **Ready for Lunch**: Highest number of orders (70), strong attach rate (39%), slightly lower margin (11.32%)  
     * **Night with the Clique**: Slightly lower attach rate (37%), lowest number of orders (51), still profitable margin (11.38%)  
   * *Insights*:  
     * Party Pack stands out as the most balanced performer, combining high attach rate, margin, and order volume — making it a flagship bundle for driving profits and perception.  
     * Naija Jollof Combo and Breakfast Starter also deliver excellent tradeoffs, with consistent performance across all key metrics.  
     * Ready for Lunch shows strong demand (highest orders), making it a volume-driven performer despite a slightly lower margin.  
     * Night with the Clique, while profitable, may need better positioning or promotional support due to lower orders and attach rate.


## Recommendations from the Data Analysis
1. **Double Down on Volume-Based Promotions**
        * Volume deals deliver +63% uplift and 2.5× higher AOV than discounts. Prioritize bulk-based offers over discounts to grow basket size without hurting margins.
2. **Bundle Around High Attach Products**    
        * Use Beer, Pasta, and Noodles as core items in bundles — they drive the most add-ons and increase basket size.  
3. **Lean Into Perceived Value Winners**  
        * Bundles like Party Pack and Naija Jollof Combo hit the sweet spot on margin and customer perception. Prioritize and expand these.
4.	**Rework Underperforming Bundles**  
        * Night with the Cliq has weak traction despite fair margins. Repackage it with more attractive anchor products or phase it out.
5.	**Geo-Target Bundle Strategy**  
        * Focus premium or upsell bundles in Abuja and Port Harcourt (highest CLV), and value bundles in Ibadan.
6.	**Use Loss Leaders Wisely**  
        * Slight discounts on high-attach products (like Beer) can pull customers into higher-margin bundles — use selectively.

## Conclusion
This analysis highlights clear levers for driving revenue and profitability: 
focus on volume-based promotions, bundle high-margin and high-attach products, and tailor strategies by city CLV. Shifting away from underperforming discounts and SKUs will sharpen commercial efficiency, while scaling high-performing bundles can further unlock growth.

## Glossary of Terms
1.  **Attach Rate**
        * Is the percentage of primary product sales that are accompanied by the purchase of a secondary product or service. It essentially measures the success of upselling or cross-selling related products.
2.  **Average Order Value (AOV)**
        * Is a key business performance indicator (KPI) that measures the average amount of money customers spend per transaction. It's calculated by dividing total revenue by the total number of orders within a specific time period.
3. **Bundles**    
        * A pricing strategy that involves combining multiple products or services into a single package sold at a discounted price or with added value compared to buying them separately.
4. **Customer Lifetime Value (CLV)**
        * Is a metric that predicts the total net profit a business expects to generate from a customer throughout their entire relationship with the company. It's a forward-thinking approach that helps businesses understand the long-term value of acquiring and retaining customers.
5. **Discounts**  
        * Is a reduction in the regular or list price of a product or service. It's a strategy used by businesses to make their offerings more attractive to customers, often to increase sales or clear out old inventory.
6.  **Gross Margin(%)**
        * Is a key measure of profitability that represents the percentage of revenue remaining after deducting the cost of goods sold (COGS), essentially showing how much profit a company makes from its core operations.
7.	**Revenue**  
        * Is the total amount of money brought in by a company's operations, measured over a set amount of time. A business's revenue is its gross income before subtracting any expenses.
8.  **Upsell**
        * Is a sales technique where a seller suggests a more expensive or upgraded version of a product or service to a customer, aiming to increase the total value of the sale. 

<br/>
   
**Thank you for taking the time to read through this project!**

**For inquiries, collaboration opportunities, or to engage my services, feel free to reach out via email: mdavidutibe@gmail.com.**

### Author
[David Utibe Michael](https://github.com/davidutibe)
