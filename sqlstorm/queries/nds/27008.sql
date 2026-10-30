
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, full_name, ca.ca_city, ca.ca_state
),
CustomerDetails AS (
    SELECT 
        co.*,
        CASE 
            WHEN total_spent > 1000 THEN 'High Value'
            WHEN total_spent > 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        CustomerOrders co
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY customer_segment ORDER BY total_spent DESC) AS rank_within_segment
    FROM 
        CustomerDetails
)
SELECT 
    customer_segment,
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_spent,
    rank_within_segment
FROM 
    RankedCustomers
WHERE 
    rank_within_segment <= 5
ORDER BY 
    customer_segment, rank_within_segment;
