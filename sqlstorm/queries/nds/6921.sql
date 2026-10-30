
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders_count
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
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0) AS total_sales
    FROM 
        CustomerSales c
    WHERE 
        (total_web_sales IS NOT NULL OR total_catalog_sales IS NOT NULL OR total_store_sales IS NOT NULL)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    CD.cd_gender,
    HD.hd_income_band_sk,
    HD.hd_buy_potential
FROM 
    TopCustomers tc
JOIN 
    customer_demographics CD ON tc.c_customer_sk = CD.cd_demo_sk
JOIN 
    household_demographics HD ON CD.cd_demo_sk = HD.hd_demo_sk
WHERE 
    total_sales > (
        SELECT AVG(total_sales) FROM TopCustomers
    )
ORDER BY 
    total_sales DESC
LIMIT 10;
