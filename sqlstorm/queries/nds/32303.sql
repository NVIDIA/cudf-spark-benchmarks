
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
top_sales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_net_profit,
        d.d_date 
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    WHERE 
        sd.rn = 1
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cd.cd_demo_sk) AS unique_demographics,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ts.total_net_profit) AS city_total_net_profit,
    COUNT(cs.c_customer_sk) AS total_customers,
    AVG(cs.max_purchase_estimate) AS avg_max_purchase_estimate
FROM 
    top_sales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk
JOIN 
    customer_stats cs ON ss.ss_customer_sk = cs.c_customer_sk
JOIN 
    customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ts.total_net_profit) > 10000
ORDER BY 
    city_total_net_profit DESC;
