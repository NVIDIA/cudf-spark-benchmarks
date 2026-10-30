
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        total_web_sales + total_catalog_sales + total_store_sales AS total_sales
    FROM 
        CustomerSales
    WHERE 
        sales_rank <= 10
),
SalesAnalytics AS (
    SELECT
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        CASE 
            WHEN tc.total_sales > 1000 THEN 'High Value'
            WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        DENSE_RANK() OVER (ORDER BY tc.total_sales DESC) AS sales_density
    FROM 
        TopCustomers tc
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.total_sales,
    sa.customer_value,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    SalesAnalytics sa
LEFT JOIN 
    web_sales ws ON sa.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    sa.c_customer_sk, sa.c_first_name, sa.c_last_name, sa.total_sales, sa.customer_value
ORDER BY 
    sa.total_sales DESC;
