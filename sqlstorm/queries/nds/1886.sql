
WITH CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerPurchaseStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
), 
StoreSalesData AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    t.customers_info,
    COALESCE(s.total_store_sales, 0) AS total_store_sales,
    CASE 
        WHEN s.total_store_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    (SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customers_info,
        c.c_customer_sk
     FROM 
        TopCustomers c) AS t
LEFT JOIN 
    StoreSalesData s ON t.c_customer_sk = s.ss_store_sk
ORDER BY 
    total_store_sales DESC;
