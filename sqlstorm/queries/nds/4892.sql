
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS grand_total_sales,
        (COALESCE(cs.web_order_count, 0) + COALESCE(ss.store_order_count, 0)) AS total_order_count
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    ts.c_customer_sk,
    ts.c_first_name,
    ts.c_last_name,
    ts.total_web_sales,
    ts.total_store_sales,
    ts.grand_total_sales,
    ts.total_order_count,
    CASE 
        WHEN ts.grand_total_sales > 1000 THEN 'High Value' 
        WHEN ts.grand_total_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    TotalSales ts
WHERE 
    ts.grand_total_sales > 0 
ORDER BY 
    ts.grand_total_sales DESC
LIMIT 10;
