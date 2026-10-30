
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') 
        AND c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_salutation, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
), 
ranked_by_spending AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        total_orders,
        total_spent,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS spending_rank
    FROM 
        ranked_customers
)
SELECT 
    rb.full_name,
    rb.ca_city,
    rb.ca_state,
    rb.total_orders,
    rb.total_spent,
    rb.spending_rank,
    CASE 
        WHEN rb.spending_rank <= 10 THEN 'Top Customer'
        WHEN rb.spending_rank <= 50 THEN 'Moderate Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    ranked_by_spending rb
ORDER BY 
    rb.ca_state, rb.spending_rank;
