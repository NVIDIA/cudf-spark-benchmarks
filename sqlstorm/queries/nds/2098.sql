
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_days
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
HighSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.order_count,
        cs.unique_ship_days,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spender_rank
    FROM CustomerSales cs
    WHERE cs.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerSales
    )
),
TopHighSpenders AS (
    SELECT 
        h.c_customer_id,
        h.total_spent AS high_spent_amount,
        h.order_count,
        h.unique_ship_days
    FROM HighSpenders h
    WHERE h.spender_rank <= 10
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ths.c_customer_id) AS number_of_top_customers,
    AVG(ths.high_spent_amount) AS avg_high_spent,
    SUM(ths.order_count) AS total_orders,
    MAX(ths.unique_ship_days) AS max_unique_ship_days
FROM TopHighSpenders ths
JOIN customer_address ca ON ths.c_customer_id = ca.ca_address_id
GROUP BY ca.ca_city
ORDER BY number_of_top_customers DESC;
