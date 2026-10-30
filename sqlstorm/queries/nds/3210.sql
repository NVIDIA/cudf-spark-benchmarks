
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_sales,
        order_count,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    tc.order_count,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_category,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk) AS store_orders_count,
    (SELECT AVG(ss.ss_net_profit) FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk) AS avg_store_profit,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = tc.c_customer_sk) AS web_return_count
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND
    (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S') 
ORDER BY 
    total_sales DESC
LIMIT 50;
