
WITH customer_full_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_address_sk DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        AVG(ws_net_paid) AS avg_net_paid,
        MAX(ws_net_profit) AS max_profit,
        MIN(ws_net_profit) AS min_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    c.ca_country,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.avg_net_paid, 0) AS avg_net_paid,
    ss.max_profit,
    ss.min_profit
FROM 
    customer_full_info c
LEFT JOIN 
    sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    (c.cd_gender = 'M' AND c.ca_state = 'CA' AND ss.total_profit > 500) 
    OR (c.cd_gender = 'F' AND ss.total_sales > 10) 
    OR (c.cd_gender IS NULL)
ORDER BY 
    total_profit DESC, 
    c.c_last_name, 
    c.c_first_name;
