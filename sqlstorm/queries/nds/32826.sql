
WITH  SalesCTE AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
MaxReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TotalSales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS net_sales,
        SUM(ss.ss_net_profit) AS net_profit
    FROM 
        store_sales ss
    JOIN 
        SalesCTE scte ON ss.ss_item_sk = scte.ss_item_sk
    GROUP BY 
        ss.ss_item_sk
),
SalesAndReturns AS (
    SELECT 
        ts.ss_item_sk,
        ts.net_sales,
        ts.net_profit,
        COALESCE(mr.return_count, 0) AS return_count,
        COALESCE(mr.total_return_amount, 0) AS total_return_amount
    FROM 
        TotalSales ts
    LEFT JOIN 
        MaxReturns mr ON ts.ss_item_sk = mr.sr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    sa.net_sales,
    sa.net_profit,
    sa.return_count,
    sa.total_return_amount,
    CASE 
        WHEN sa.return_count > 0 THEN 'High Return'
        WHEN sa.net_sales > 1000 THEN 'High Sales'
        ELSE 'Regular'
    END AS sales_status
FROM 
    CustomerInfo ci
JOIN 
    SalesAndReturns sa ON ci.c_customer_sk = sa.ss_item_sk
ORDER BY 
    sa.net_sales DESC
LIMIT 100;
