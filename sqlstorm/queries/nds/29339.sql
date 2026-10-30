
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk, d.d_year, d.d_month_seq
),
combined_info AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        si.total_quantity,
        si.total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_ship_date_sk
    LEFT JOIN 
        date_dim d ON si.ws_ship_date_sk = d.d_date_sk
)
SELECT 
    full_name,
    SUM(total_quantity) AS aggregated_quantity,
    SUM(total_profit) AS aggregated_profit,
    COUNT(DISTINCT d_year) AS unique_years,
    COUNT(DISTINCT d_month_seq) AS unique_months
FROM 
    combined_info
GROUP BY 
    full_name
ORDER BY 
    aggregated_profit DESC
LIMIT 100;
