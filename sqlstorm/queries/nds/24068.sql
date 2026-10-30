
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sale_rank,
        CASE 
            WHEN ws_sales_price IS NULL THEN 'Unknown Price'
            ELSE CAST(ws_sales_price AS STRING)
        END AS price_category
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), AggregatedSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_price,
        COUNT(*) FILTER (WHERE rs.ws_quantity > 0) AS positive_sales_count,
        COUNT(*) AS total_sales_count,
        MAX(rs.ws_sales_price) AS max_price,
        MIN(rs.ws_sales_price) AS min_price
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
), SalesWithRevenue AS (
    SELECT 
        ag.*, 
        ag.total_sales / NULLIF(ag.total_sales_count, 0) AS avg_sales_value,
        CASE 
            WHEN ag.total_sales > 10000 THEN 'High Revenue'
            WHEN ag.total_sales > 0 THEN 'Low Revenue'
            ELSE 'No Revenue'
        END AS revenue_category
    FROM 
        AggregatedSales ag
), StoreCustomerDetails AS (
    SELECT 
        cs.ss_item_sk,
        SUM(cs.ss_sales_price) AS store_total_sales,
        COALESCE(AVG(cs.ss_sales_price), 0) AS store_avg_price
    FROM 
        store_sales cs
    GROUP BY 
        cs.ss_item_sk
)

SELECT 
    swr.ws_item_sk,
    swr.total_sales,
    swr.avg_price,
    swr.positive_sales_count,
    swr.total_sales_count,
    swr.avg_sales_value,
    swr.revenue_category,
    sct.store_total_sales,
    sct.store_avg_price
FROM 
    SalesWithRevenue swr
LEFT JOIN 
    StoreCustomerDetails sct ON swr.ws_item_sk = sct.ss_item_sk
WHERE 
    swr.revenue_category = 'High Revenue' 
    OR (swr.revenue_category = 'No Revenue' AND sct.store_total_sales IS NULL)
ORDER BY 
    swr.total_sales DESC
LIMIT 20 OFFSET 10;
