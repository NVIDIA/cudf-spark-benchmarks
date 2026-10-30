WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA' AND 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2000)
    GROUP BY 
        ss.ss_store_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        ss.total_store_sales,
        cs.web_order_count,
        cs.catalog_order_count,
        ss.store_order_count,
        ss.avg_net_profit
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = (SELECT MAX(c.c_customer_id) FROM customer c) 
)
SELECT 
    COALESCE(ts.c_customer_id, 'No Customer') AS customer_id,
    COALESCE(ts.total_web_sales, 0) AS total_web_sales,
    COALESCE(ts.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(ts.total_store_sales, 0) AS total_store_sales,
    ts.web_order_count,
    ts.catalog_order_count,
    ts.store_order_count,
    ts.avg_net_profit
FROM 
    TotalSales ts
WHERE 
    (ts.total_web_sales > 1000 OR ts.total_catalog_sales > 500) 
ORDER BY 
    total_web_sales DESC, 
    total_catalog_sales DESC;