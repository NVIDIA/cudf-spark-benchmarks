
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        (i.i_current_price BETWEEN 10 AND 50) AND 
        (ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
        OR ws.ws_sold_date_sk < (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2021))
    GROUP BY 
        ws.ws_item_sk
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        (i.i_current_price BETWEEN 10 AND 50) AND 
        (cs.cs_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
        OR cs.cs_sold_date_sk < (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2021))
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.total_profit,
    COALESCE(d.cd_gender, 'UNKNOWN') AS customer_gender,
    d.cd_marital_status,
    d.cd_purchase_estimate,
    RANK() OVER (ORDER BY total_profit DESC) AS overall_rank
FROM 
    sales_data s
LEFT JOIN 
    customer c ON s.ws_item_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE 
    total_profit > 1000
ORDER BY 
    overall_rank,
    s.total_quantity DESC;
