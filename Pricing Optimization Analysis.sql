--call database
use practise;

--view entire table
select
	*
from
	dbo.Pricing_Dataset;

-- Data Transformation
--1.  rename cost_price column  to match the name for other columns
EXEC sp_rename 'Pricing_Dataset.Cost_Price', 'CostPrice', 'COLUMN';

--2. Changing column data types
alter table Pricing_Dataset
alter column UnitPrice int;
alter table Pricing_Dataset
alter column CostPrice int;
alter table Pricing_Dataset
alter column ProductID Decimal;

--Data Analysis
--1.  Gross Margin for top 5 SKUs
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

--2. Comparing Promo Uplift for discount based promos vs volume deal promos.
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

--3. Which Promo resulted in higher AOV
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

--4. Which Products drive the most add-ons?
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

-- 5. Customer Lifetime Segmentation by City
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

--6. Which bundles give the best margin vs perception tradeoff?
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
	




