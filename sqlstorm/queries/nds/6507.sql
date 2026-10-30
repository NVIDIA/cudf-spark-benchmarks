
WITH aggregated_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity_per_order,
        MAX(ws.ws_net_paid) AS max_transaction,
        MIN(ws.ws_net_paid) AS min_transaction
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_state
),
profit_summary AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.ca_state,
        SUM(a.total_profit) AS total_profit,
        SUM(a.order_count) AS total_orders,
        AVG(a.avg_quantity_per_order) AS avg_quantity
    FROM 
        aggregated_sales a
    JOIN 
        demographics d ON d.customer_count > 0
    GROUP BY 
        d.cd_gender, d.cd_marital_status, d.cd_education_status, d.ca_state
)
SELECT 
    ps.cd_gender,
    ps.cd_marital_status,
    ps.cd_education_status,
    ps.ca_state,
    ps.total_profit,
    ps.total_orders,
    ps.avg_quantity
FROM 
    profit_summary ps
WHERE 
    ps.total_profit > 10000
ORDER BY 
    ps.total_profit DESC;
