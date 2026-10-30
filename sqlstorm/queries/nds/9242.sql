
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_days
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
        COUNT(DISTINCT ss.ss_sold_date_sk) AS unique_store_ship_days
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
),
SalesComparison AS (
    SELECT 
        COALESCE(cs.c_customer_sk, ss.c_customer_sk) AS customer_sk,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        CASE 
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(ss.total_store_sales, 0) THEN 'Web'
            WHEN COALESCE(cs.total_web_sales, 0) < COALESCE(ss.total_store_sales, 0) THEN 'Store'
            ELSE 'Equal'
        END AS preferred_channel
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)
SELECT 
    preferred_channel,
    COUNT(customer_sk) AS number_of_customers,
    SUM(web_sales) AS total_web_sales,
    SUM(store_sales) AS total_store_sales
FROM 
    SalesComparison
GROUP BY 
    preferred_channel
ORDER BY 
    number_of_customers DESC, total_web_sales DESC;
