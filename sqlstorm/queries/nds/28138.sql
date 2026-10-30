
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ci.full_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name
),
state_summary AS (
    SELECT 
        ci.ca_state,
        COUNT(DISTINCT ci.c_customer_sk) AS number_of_customers,
        SUM(ss.total_spent) AS total_revenue
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.full_name = ss.full_name
    GROUP BY 
        ci.ca_state
)
SELECT 
    s.ca_state, 
    s.number_of_customers, 
    s.total_revenue,
    RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
FROM 
    state_summary s
WHERE 
    s.total_revenue > 0
ORDER BY 
    s.total_revenue DESC;
