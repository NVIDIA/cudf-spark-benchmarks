
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_net_paid_inc_tax) AS total_amount_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_summary AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    COALESCE(ss.total_orders, 0) AS orders_placed,
    COALESCE(ss.total_net_profit, 0) AS net_profit,
    COALESCE(ss.total_amount_paid, 0) AS amount_paid,
    COALESCE(rs.total_returns, 0) AS returns_made
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    returns_summary rs ON ci.c_customer_sk = rs.sr_customer_sk
WHERE 
    ci.cd_marital_status = 'M' AND 
    (ci.cd_purchase_estimate > 500 OR ci.cd_purchase_estimate IS NULL)
ORDER BY 
    ci.c_last_name ASC,
    ci.c_first_name ASC;
