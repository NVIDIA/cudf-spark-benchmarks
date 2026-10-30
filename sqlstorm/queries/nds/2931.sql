
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_sales_count,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_sales_count
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_paid,
        cs.store_sales_count,
        cs.web_sales_count,
        RANK() OVER (ORDER BY cs.total_net_paid DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_net_paid,
    sr.store_sales_count,
    sr.web_sales_count,
    CASE 
        WHEN sr.total_net_paid IS NULL THEN 'No Sales'
        WHEN sr.total_net_paid > 1000 THEN 'High Value Customer'
        WHEN sr.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    SalesRanked sr
WHERE 
    sr.sales_rank <= 100
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    'Total Customers' AS c_first_name,
    NULL AS c_last_name,
    SUM(total_net_paid) AS total_net_paid,
    SUM(store_sales_count) AS store_sales_count,
    SUM(web_sales_count) AS web_sales_count,
    'Aggregate' AS customer_value_category
FROM 
    CustomerSales;
