
WITH  customer_expenditure AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
active_customers AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(MAX(ws.ws_sold_date_sk), 0) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_analysis AS (
    SELECT 
        ce.c_customer_sk,
        ce.total_spent,
        ce.order_count,
        CASE 
            WHEN ac.last_purchase_date = 0 THEN 'Inactive'
            WHEN ce.order_count = 0 THEN 'No Orders'
            ELSE 'Active'
        END AS activity_status,
        ce.spending_rank
    FROM 
        customer_expenditure ce
    JOIN 
        active_customers ac ON ce.c_customer_sk = ac.c_customer_sk
)
SELECT 
    c.c_customer_id,
    ca.total_spent,
    ca.order_count,
    ca.activity_status,
    CASE 
        WHEN ca.spending_rank <= 10 THEN 'Top Spender'
        WHEN ca.total_spent IS NULL THEN 'No Expenditure'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    customer_analysis ca
JOIN 
    customer c ON ca.c_customer_sk = c.c_customer_sk
WHERE 
    (ca.order_count > 5 OR ca.activity_status = 'Inactive')
    AND COALESCE(c.c_birth_month, 0) <> 2
ORDER BY 
    ca.total_spent DESC
LIMIT 50
OFFSET 10;
