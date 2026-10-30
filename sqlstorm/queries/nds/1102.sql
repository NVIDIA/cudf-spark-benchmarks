
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.orders_count,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.orders_count, 0) AS orders_count,
    tc.last_purchase_date,
    COALESCE((SELECT AVG(total_sales) 
              FROM CustomerSales 
              WHERE total_sales > 500), 0) AS avg_sales_above_500,
    CASE 
        WHEN tc.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Ranked Customer'
    END AS customer_status
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND (cd.cd_marital_status = 'M' OR cd.cd_purchase_estimate > 500)
ORDER BY 
    tc.total_sales DESC;
