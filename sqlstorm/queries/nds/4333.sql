
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS overall_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_web_sales > 1000 OR cs.total_catalog_sales > 1000 OR cs.total_store_sales > 1000
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_web_sales,
    rc.total_catalog_sales,
    rc.total_store_sales,
    rc.overall_rank,
    (SELECT COUNT(DISTINCT ss_ticket_number) FROM store_sales WHERE ss_customer_sk = rc.c_customer_sk) AS distinct_store_sales_count,
    (SELECT COUNT(1) FROM store_returns sr WHERE sr.sr_customer_sk = rc.c_customer_sk) AS store_returns_count
FROM 
    RankedCustomers rc
WHERE 
    rc.overall_rank <= 10
ORDER BY 
    rc.overall_rank;
