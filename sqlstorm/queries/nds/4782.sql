
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_order_count,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_returns
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_returns AS cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesStatistics AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.web_order_count,
        cs.store_order_count,
        cs.total_web_quantity,
        cs.total_store_quantity,
        cs.total_catalog_returns,
        PERCENT_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS web_sales_rank,
        PERCENT_RANK() OVER (ORDER BY cs.total_store_quantity DESC) AS store_quantity_rank
    FROM 
        CustomerSales AS cs
)
SELECT 
    s.c_customer_sk,
    s.total_web_sales,
    s.web_order_count,
    s.store_order_count,
    s.total_web_quantity,
    s.total_store_quantity,
    s.total_catalog_returns,
    CASE 
        WHEN s.total_web_sales > 1000 THEN 'High Spender'
        WHEN s.total_web_sales BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS customer_segment,
    CASE 
        WHEN s.web_sales_rank IS NULL THEN 'No Sales'
        ELSE 'Ranked'
    END AS sales_rank_status
FROM 
    SalesStatistics AS s
WHERE 
    s.store_order_count > 5 
    OR s.total_catalog_returns > 0
ORDER BY 
    s.total_web_sales DESC
LIMIT 100;
