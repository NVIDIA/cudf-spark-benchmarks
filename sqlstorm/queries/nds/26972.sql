WITH matched_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city LIKE '%Spring%' AND 
        (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
),
item_summary AS (
    SELECT
        i.i_item_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
),
final_report AS (
    SELECT 
        mc.full_name,
        mc.ca_city,
        mc.ca_state,
        it.i_item_sk,
        it.total_sales,
        it.total_net_profit
    FROM 
        matched_customers mc
    JOIN 
        item_summary it ON mc.c_customer_sk = it.i_item_sk 
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    COUNT(DISTINCT i_item_sk) AS unique_items,
    SUM(total_net_profit) AS total_net_profit,
    AVG(total_sales) AS avg_sales_per_item
FROM 
    final_report
GROUP BY 
    full_name, ca_city, ca_state
ORDER BY 
    total_net_profit DESC;