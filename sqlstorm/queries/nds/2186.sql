
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesMetrics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        NTILE(4) OVER (ORDER BY cs.total_sales DESC) AS sales_quartile,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < 100 THEN 'Low Sales'
            WHEN cs.total_sales BETWEEN 100 AND 500 THEN 'Medium Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        CustomerSales cs
)
SELECT 
    sm.c_customer_sk,
    sm.c_first_name,
    sm.c_last_name,
    sm.total_sales,
    sm.order_count,
    sm.sales_quartile,
    sm.sales_category,
    COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
    COALESCE(hd.hd_buy_potential, 'Pending') AS buy_potential
FROM 
    SalesMetrics sm
LEFT JOIN 
    customer_demographics cd ON sm.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    household_demographics hd ON sm.c_customer_sk = hd.hd_demo_sk
WHERE 
    sm.total_sales IS NOT NULL
    AND (sm.sales_category = 'High Sales' OR sm.sales_category = 'Medium Sales')
ORDER BY 
    sm.total_sales DESC
LIMIT 100;
