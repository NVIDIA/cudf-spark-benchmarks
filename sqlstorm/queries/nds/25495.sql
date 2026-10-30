
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk,
        CASE 
            WHEN hd.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
            WHEN hd.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
detailed_report AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.income_category,
        ps.total_orders,
        ps.total_spent
    FROM 
        customer_info ci
    LEFT JOIN 
        purchase_summary ps ON ci.c_customer_sk = ps.c_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_spent IS NULL THEN 'No Purchases'
        WHEN total_spent < 100 THEN 'Budget Shopper'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Savvy Shopper'
        ELSE 'Premium Buyer'
    END AS shopper_type
FROM 
    detailed_report
ORDER BY 
    total_spent DESC NULLS LAST;
