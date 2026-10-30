
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ss.ss_net_paid), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RecentPurchases AS (
    SELECT 
        c.c_customer_sk,
        MAX(ws.ws_sold_date_sk) AS last_web_purchase,
        MAX(ss.ss_sold_date_sk) AS last_store_purchase
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_store_sales,
    cs.total_web_sales,
    rp.last_web_purchase,
    rp.last_store_purchase,
    CASE 
        WHEN cs.total_store_sales > cs.total_web_sales THEN 'Store'
        WHEN cs.total_web_sales > cs.total_store_sales THEN 'Web'
        ELSE 'Equal'
    END AS preferred_channel
FROM 
    CustomerSales cs
JOIN 
    RecentPurchases rp ON cs.c_customer_sk = rp.c_customer_sk
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.total_store_sales DESC, cs.total_web_sales DESC;
