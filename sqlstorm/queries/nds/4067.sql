
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        cs.sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS total_web_sales_female_customers,
    COALESCE((SELECT COUNT(sr_item_sk) 
              FROM store_returns 
              WHERE sr_customer_sk = tc.c_customer_sk 
              AND sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_month = 'Y')), 0) AS return_count,
    CASE 
        WHEN tc.total_orders > 0 THEN ROUND((tc.total_web_sales / NULLIF(tc.total_orders, 0)), 2) 
        ELSE 0 
    END AS average_order_value
FROM 
    TopCustomers tc 
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    total_web_sales DESC;
