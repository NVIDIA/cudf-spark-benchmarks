
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city || ', ' || ca.ca_state AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.full_address,
        ss.total_orders,
        ss.total_spent,
        ss.avg_order_value
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.total_orders > 5
    ORDER BY 
        ss.total_spent DESC
    LIMIT 10
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    full_address, 
    total_orders, 
    total_spent, 
    avg_order_value, 
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM 
    top_customers;
