
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        cs.total_spent,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    rs.first_name,
    rs.last_name,
    COALESCE(rs.total_spent, 0) AS total_spent,
    COALESCE(rs.total_orders, 0) AS total_orders,
    CASE 
        WHEN rs.total_spent IS NULL THEN 'No Purchases'
        WHEN rs.total_spent > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    RankedSales rs
LEFT JOIN 
    customer_demographics cd ON rs.customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY 
    rs.total_spent DESC
LIMIT 10;
