
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales)
),
store_performance AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
),
sales_by_state AS (
    SELECT 
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        store s
    JOIN 
        customer_address ca ON s.s_street_number = ca.ca_street_number
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    hvc.c_customer_id AS customer_id,
    hvc.c_first_name AS first_name,
    hvc.c_last_name AS last_name,
    hvc.total_spent,
    hvc.total_orders,
    sp.s_store_id,
    sp.total_sales,
    sp.total_transactions,
    sbs.ca_state,
    sbs.total_sales AS state_sales,
    COALESCE(MAX(hvc.total_spent) OVER (PARTITION BY sbs.ca_state), 0) AS max_spent_in_state
FROM 
    high_value_customers hvc
CROSS JOIN 
    store_performance sp
JOIN 
    sales_by_state sbs ON sp.total_sales > sbs.total_sales
WHERE 
    hvc.rank <= 10
ORDER BY 
    hvc.total_spent DESC, sp.total_sales DESC;
