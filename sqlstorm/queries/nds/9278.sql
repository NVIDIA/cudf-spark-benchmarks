
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        AVG(ws_quantity) AS avg_quantity 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        sd.total_net_profit,
        sd.total_orders,
        sd.avg_sales_price,
        sd.avg_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
state_analysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(sd.total_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY 
        ca_state
)
SELECT 
    ca.ca_state,
    SUM(ca.customer_count) AS total_customers,
    SUM(ca.total_profit) AS state_profit,
    AVG(cu.avg_sales_price) AS avg_sales_price_per_state,
    AVG(cu.avg_quantity) AS avg_quantity_per_state
FROM 
    state_analysis ca
JOIN 
    customer_analysis cu ON ca.customer_count = cu.total_orders
GROUP BY 
    ca.ca_state
ORDER BY 
    state_profit DESC;
