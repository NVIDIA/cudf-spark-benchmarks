
WITH customer_stats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state
),
sales_stats AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk,
        ws.ws_item_sk
)
SELECT 
    cs.ca_state,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    ss.total_quantity,
    ss.total_net_profit,
    cs.customer_count,
    cs.female_count,
    cs.male_count,
    cs.avg_purchase_estimate
FROM 
    customer_stats cs
LEFT JOIN 
    sales_stats ss ON cs.customer_count > 0
ORDER BY 
    cs.ca_state, 
    cs.cd_gender;
