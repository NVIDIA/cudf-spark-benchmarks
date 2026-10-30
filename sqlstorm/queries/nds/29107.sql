
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        full_name,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
    WHERE 
        total_sales > 0
)
SELECT 
    full_name,
    total_sales,
    total_orders,
    sales_rank,
    CASE 
        WHEN sales_rank <= 10 THEN 'Top 10 Customers'
        WHEN sales_rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Other Customers'
    END AS customer_segment
FROM 
    TopCustomers
ORDER BY 
    sales_rank;
