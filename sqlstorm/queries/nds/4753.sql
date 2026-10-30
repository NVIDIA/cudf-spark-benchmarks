
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        cs.web_orders,
        COALESCE(ss.store_orders, 0) AS store_orders,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        CASE 
            WHEN cs.web_orders > ss.store_orders THEN 'More web orders'
            WHEN cs.web_orders < ss.store_orders THEN 'More store orders'
            ELSE 'Equal orders'
        END AS order_comparison
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
),
RankedSales AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY order_comparison ORDER BY total_sales DESC) AS order_rank
    FROM 
        CombinedSales c
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_store_sales,
    r.total_sales,
    r.order_comparison,
    r.sales_rank,
    r.order_rank
FROM 
    RankedSales r
WHERE 
    r.total_sales IS NOT NULL
    AND r.total_sales > (SELECT AVG(total_sales) FROM CombinedSales)
ORDER BY 
    r.total_sales DESC;
