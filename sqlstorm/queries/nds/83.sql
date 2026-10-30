
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        c.*, 
        CASE 
            WHEN total_sales > 10000 THEN 'High Value'
            WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                              WHEN total_sales > 10000 THEN 'High Value'
                                              WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
                                              ELSE 'Low Value'
                                          END ORDER BY total_sales DESC) as rn
    FROM 
        CustomerSales c
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_sales,
    tc.customer_value,
    CONCAT('Sales Record Count: ', (tc.store_sales_count + tc.catalog_sales_count + tc.web_sales_count)) AS sales_record_count_message
FROM 
    TopCustomers tc
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.customer_value, tc.total_sales DESC;
