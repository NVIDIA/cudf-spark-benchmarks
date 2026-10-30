
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS sales_rank
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS customer_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.cs_item_sk,
        rs.cs_order_number,
        rs.cs_sales_price,
        cr.total_returned,
        cr.customer_count
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.cs_item_sk = cr.wr_item_sk
)

SELECT 
    swr.cs_item_sk,
    swr.cs_sales_price,
    COALESCE(swr.total_returned, 0) AS total_returned,
    COALESCE(swr.customer_count, 0) AS customer_count,
    CASE 
        WHEN COALESCE(swr.total_returned, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN swr.cs_sales_price > 100 THEN 'High Price'
        WHEN swr.cs_sales_price BETWEEN 50 AND 100 THEN 'Medium Price'
        ELSE 'Low Price'
    END AS price_category
FROM 
    SalesWithReturns swr
WHERE 
    swr.cs_sales_price > (SELECT AVG(cs_sales_price) FROM catalog_sales)
ORDER BY 
    swr.cs_sales_price DESC;
