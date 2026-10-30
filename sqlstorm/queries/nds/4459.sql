
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COALESCE(NULLIF(SUM(ws.ws_ext_sales_price), 0), NULLIF(SUM(cs.cs_ext_sales_price), 0), NULLIF(SUM(ss.ss_ext_sales_price), 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
    WHERE
        cs.total_sales IS NOT NULL
),
TopCustomers AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.total_web_sales,
        r.total_catalog_sales,
        r.total_store_sales,
        r.total_sales
    FROM
        RankedSales r
    WHERE
        r.sales_rank <= 10
)

SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS web_sales,
    COALESCE(tc.total_catalog_sales, 0) AS catalog_sales,
    COALESCE(tc.total_store_sales, 0) AS store_sales,
    COALESCE(tc.total_sales, 0) AS total_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales Record'
        WHEN tc.total_sales > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_category,
    CASE 
        WHEN tc.total_web_sales IS NOT NULL THEN 'Web Customer'
        WHEN tc.total_catalog_sales IS NOT NULL THEN 'Catalog Customer'
        WHEN tc.total_store_sales IS NOT NULL THEN 'Store Customer'
        ELSE 'No Purchase Channel'
    END AS purchase_channel
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;
