
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
RecentSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS sales_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS rnk
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_id,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rs.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(rr.total_returned, 0) > 0 THEN 'High Return'
            WHEN COALESCE(rs.total_sales, 0) > 1000 THEN 'High Value'
            ELSE 'Normal'
        END AS customer_category
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns rr ON c.c_customer_sk = rr.sr_customer_sk
    LEFT JOIN 
        RecentSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT
    customer_category,
    COUNT(c_customer_id) AS customer_count,
    AVG(total_returned) AS avg_returned,
    SUM(total_sales) AS total_sales,
    SUM(CASE WHEN total_returned > 0 THEN 1 ELSE 0 END) AS high_return_count,
    SUM(CASE WHEN customer_category = 'High Value' THEN 1 ELSE 0 END) AS high_value_count,
    MAX(total_sales) AS max_sales_per_customer,
    MIN(total_sales) AS min_sales_per_customer
FROM 
    CombinedData
GROUP BY 
    customer_category 
HAVING 
    COUNT(c_customer_id) > 0
ORDER BY 
    customer_category DESC
LIMIT 10;
