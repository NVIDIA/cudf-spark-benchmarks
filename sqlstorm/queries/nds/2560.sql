
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ranked_sales AS (
    SELECT 
        cs.*, 
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY cs_net_profit DESC) AS rank
    FROM 
        catalog_sales cs
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ss.total_profit,
    ss.total_orders,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.ca_state,
    RANK() OVER (ORDER BY ss.total_profit DESC) AS profit_rank
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    ranked_sales rs ON rs.cs_bill_customer_sk = ci.c_customer_sk AND rs.rank = 1
WHERE 
    (ci.cd_purchase_estimate IS NOT NULL OR 
    (ci.cd_marital_status = 'M' AND ci.cd_gender = 'F'))
ORDER BY 
    ss.total_profit DESC, 
    ci.c_last_name ASC
LIMIT 100;
