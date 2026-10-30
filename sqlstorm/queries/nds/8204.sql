WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450580 AND 2450585 
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
high_value_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_spent,
        rc.order_count,
        rc.gender_rank
    FROM ranked_customers rc
    WHERE rc.gender_rank <= 10
),
state_summary AS (
    SELECT 
        ca.ca_state,
        SUM(hvc.total_spent) AS state_total_spent,
        COUNT(hvc.c_customer_sk) AS customer_count
    FROM high_value_customers hvc
    JOIN customer c ON hvc.c_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT 
    ss.ca_state,
    ss.state_total_spent,
    ss.customer_count,
    RANK() OVER (ORDER BY ss.state_total_spent DESC) AS state_rank
FROM state_summary ss
ORDER BY ss.state_total_spent DESC;