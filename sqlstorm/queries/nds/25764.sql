
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
), web_sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.cd_purchase_estimate,
    rc.cd_credit_rating,
    asu.ca_city,
    asu.ca_state,
    COALESCE(wss.total_sales, 0) AS total_sales,
    COALESCE(wss.total_profit, 0) AS total_profit
FROM 
    ranked_customers rc
LEFT JOIN 
    address_summary asu ON rc.c_customer_sk = asu.customer_count
LEFT JOIN 
    web_sales_summary wss ON rc.c_customer_sk = wss.ws_bill_customer_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_purchase_estimate DESC;
