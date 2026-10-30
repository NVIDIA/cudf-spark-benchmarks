
WITH  sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS rn
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN 20210101 AND 20211231
),
top_sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        sales_data sd
    WHERE 
        sd.rn <= 10
    GROUP BY 
        sd.ws_sold_date_sk, sd.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ci.ca_city AS c_city,
        ci.ca_state AS c_state,
        SUM(ts.total_quantity) AS total_quantity,
        SUM(ts.total_profit) AS total_profit
    FROM 
        top_sales ts
    JOIN 
        customer_info ci ON ci.c_customer_sk = ts.ws_item_sk
    GROUP BY 
        ci.ca_city, ci.ca_state
),
ranked_sales AS (
    SELECT 
        c_city, 
        c_state, 
        total_quantity, 
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        sales_summary
)
SELECT 
    rs.c_city,
    rs.c_state,
    rs.total_quantity,
    rs.total_profit,
    CASE 
        WHEN rs.profit_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS sales_category
FROM 
    ranked_sales rs
WHERE 
    rs.total_profit IS NOT NULL
ORDER BY 
    rs.total_profit DESC, 
    rs.c_city;
