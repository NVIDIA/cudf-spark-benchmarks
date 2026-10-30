
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
purchase_summary AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ci.c_email_address
),
income_bracket AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ps.full_name,
    ps.c_email_address,
    ps.total_orders,
    ps.total_spent,
    CASE
        WHEN ps.total_spent < ib.ib_lower_bound THEN 'Below Minimum'
        WHEN ps.total_spent >= ib.ib_lower_bound AND ps.total_spent <= ib.ib_upper_bound THEN 'In Income Band'
        ELSE 'Above Maximum'
    END AS income_level,
    ci.ca_state
FROM 
    purchase_summary ps
JOIN 
    customer_info ci ON ps.full_name = ci.full_name AND ps.c_email_address = ci.c_email_address
JOIN 
    income_bracket ib ON ci.c_customer_sk = ib.cd_demo_sk
ORDER BY 
    ps.total_spent DESC;
