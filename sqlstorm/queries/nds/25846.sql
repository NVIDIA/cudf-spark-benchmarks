
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city LIKE '%ville%'
        AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        FilteredCustomers c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopSpendingCustomers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        s.total_orders,
        s.total_spent
    FROM 
        SalesSummary s
    JOIN 
        FilteredCustomers c ON s.c_customer_sk = c.c_customer_sk
    WHERE 
        s.total_spent > (SELECT AVG(total_spent) FROM SalesSummary)
)
SELECT 
    CONCAT(t.c_first_name, ' ', t.c_last_name) AS customer_name,
    t.total_orders,
    t.total_spent,
    CASE 
        WHEN t.total_spent BETWEEN 1000 AND 5000 THEN 'Moderate'
        WHEN t.total_spent > 5000 THEN 'High'
        ELSE 'Low'
    END AS spending_category
FROM 
    TopSpendingCustomers t
ORDER BY 
    t.total_spent DESC
LIMIT 10;
