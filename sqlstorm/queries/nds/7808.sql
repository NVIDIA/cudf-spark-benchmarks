
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.last_purchase_date,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    tc.last_purchase_date,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10 Customers'
        WHEN tc.sales_rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    TopCustomers tc
WHERE 
    tc.last_purchase_date >= (SELECT MAX(d.d_date_sk) 
                               FROM date_dim d 
                               WHERE d.d_year = 2022)
ORDER BY 
    tc.total_sales DESC;
