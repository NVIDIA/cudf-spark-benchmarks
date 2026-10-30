
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High Value'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        CustomerSales cs
),
TopCustomers AS (
    SELECT 
        customer_value_category,
        COUNT(c_customer_id) AS customer_count,
        AVG(total_spent) AS avg_spent,
        RANK() OVER (ORDER BY COUNT(c_customer_id) DESC) AS rank
    FROM 
        SalesAnalysis
    GROUP BY 
        customer_value_category
)
SELECT 
    customer_value_category,
    customer_count,
    avg_spent,
    rank
FROM 
    TopCustomers
WHERE 
    rank <= 3
ORDER BY 
    rank;
