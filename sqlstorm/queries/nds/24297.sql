
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as rn,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) as total_sales
    FROM 
        web_sales
),
HighValueSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        CASE 
            WHEN r.total_sales > 10000 THEN 'High'
            ELSE 'Low'
        END AS sales_category
    FROM 
        RankedSales r
    WHERE 
        r.rn = 1
),
StoreSalesSummary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS sales_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ss_item_sk
)
SELECT 
    h.ws_item_sk,
    h.ws_order_number,
    h.ws_sales_price,
    COALESCE(s.total_net_profit, 0) AS total_store_net_profit,
    h.sales_category
FROM 
    HighValueSales h
LEFT JOIN 
    StoreSalesSummary s ON h.ws_item_sk = s.ss_item_sk
WHERE 
    h.sales_category = 'High'
    AND (h.ws_sales_price >= (SELECT AVG(ws_sales_price) FROM web_sales) 
         OR h.ws_sales_price IS NULL)
ORDER BY 
    h.ws_sales_price DESC
LIMIT 10;
