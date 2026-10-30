
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id AS customer_id,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_items_sold,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    t.customer_id,
    t.total_items_sold,
    t.total_sales,
    t.total_orders
FROM 
    TopCustomers t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
