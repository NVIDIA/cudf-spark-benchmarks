
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_paid) DESC) AS state_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, 
        cd.cd_credit_rating, cd.cd_dep_count, 
        cd.cd_dep_college_count, ca.ca_city, ca.ca_state
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.total_orders,
        ci.total_spent,
        ci.state_rank,
        ROW_NUMBER() OVER (ORDER BY ci.total_spent DESC) AS overall_rank
    FROM customer_info ci
    WHERE ci.total_orders > (SELECT AVG(total_orders) FROM customer_info)
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_orders, 0) AS orders,
    COALESCE(tc.total_spent, 0.00) AS spent,
    CASE 
        WHEN tc.state_rank = 1 THEN 'Top spender in state'
        WHEN tc.state_rank IS NULL THEN 'No orders'
        ELSE 'Average spender'
    END AS spending_category
FROM top_customers tc
FULL OUTER JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'S' OR cd.cd_gender = 'F'
ORDER BY tc.overall_rank, tc.state_rank;
