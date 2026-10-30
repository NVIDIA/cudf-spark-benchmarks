WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DATE_PART('year', cast('2002-10-01' as date)) - c.c_birth_year AS age,
        ca.ca_state,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_purchase_estimate, c.c_birth_year, 
        ca.ca_state
),
filtered_customers AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent > 10000 THEN 'High Value'
            WHEN total_spent > 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_data
    WHERE 
        age BETWEEN 25 AND 45 AND 
        cd_gender = 'F' AND
        ca_state = 'CA'
),
final_metrics AS (
    SELECT 
        customer_value,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(total_spent) AS total_revenue
    FROM 
        filtered_customers
    GROUP BY 
        customer_value
)
SELECT 
    customer_value,
    customer_count,
    avg_purchase_estimate,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    final_metrics
ORDER BY 
    revenue_rank;