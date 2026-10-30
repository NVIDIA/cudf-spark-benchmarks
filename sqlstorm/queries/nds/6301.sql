
WITH customer_orders AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, d.d_year
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS rank
    FROM 
        customer_orders
)
SELECT 
    c.c_customer_id,
    t.total_net_profit,
    t.total_orders,
    t.average_order_value,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status,
    t.ca_city,
    t.ca_state,
    t.d_year
FROM 
    top_customers t
JOIN 
    customer c ON t.c_customer_id = c.c_customer_id
WHERE 
    t.rank <= 10
ORDER BY 
    t.d_year, t.total_net_profit DESC;
