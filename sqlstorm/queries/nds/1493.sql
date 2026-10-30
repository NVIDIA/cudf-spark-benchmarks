
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        cs.avg_order_value
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent IS NOT NULL AND cs.total_orders > 5
),
HighValueCustomers AS (
    SELECT 
        f.c_customer_sk,
        f.c_first_name,
        f.c_last_name,
        f.total_spent,
        f.total_orders,
        f.avg_order_value,
        RANK() OVER (ORDER BY f.total_spent DESC) AS sales_rank
    FROM 
        FilteredSales f
)
SELECT 
    h.*,
    CASE 
        WHEN h.avg_order_value > 100 THEN 'High Value'
        WHEN h.avg_order_value BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    HighValueCustomers h
WHERE 
    h.sales_rank <= 10
ORDER BY 
    h.total_spent DESC;
