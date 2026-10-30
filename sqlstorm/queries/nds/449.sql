
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
        AND c.c_first_shipto_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS customer_category,
    SUM(CASE 
        WHEN ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231 THEN ws.ws_ext_sales_price 
        ELSE NULL 
    END) AS current_year_sales,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_sales, tc.total_orders, tc.sales_rank
ORDER BY 
    tc.sales_rank;
