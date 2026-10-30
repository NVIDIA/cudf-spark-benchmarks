WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > 0
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status IN ('M', 'D') 
        AND cd.cd_purchase_estimate IS NOT NULL
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(i.i_current_price, 0) AS i_current_price
    FROM 
        item i
    WHERE 
        i.i_rec_end_date >= cast('2002-10-01' as date)
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    rs.ws_item_sk,
    id.i_item_desc,
    id.i_current_price,
    SUM(rs.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT rs.ws_sales_price) AS distinct_sales_count,
    CASE 
        WHEN SUM(rs.ws_net_profit) > 10000 THEN 'High Profit'
        WHEN SUM(rs.ws_net_profit) BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    COALESCE(MAX (CASE WHEN rs.sales_rank = 1 THEN rs.ws_sales_price END), 0) AS max_sales_price
FROM 
    ranked_sales rs
JOIN 
    customer_info ci ON rs.ws_item_sk = ci.c_customer_sk
JOIN 
    item_details id ON rs.ws_item_sk = id.i_item_sk
LEFT JOIN 
    store_returns sr ON sr.sr_item_sk = rs.ws_item_sk AND sr.sr_return_quantity > 0
    AND (sr.sr_return_amt IS NULL OR sr.sr_return_amt < 100)
WHERE 
    (rs.ws_sales_price + id.i_current_price) % 2 = 0
GROUP BY 
    ci.c_first_name, ci.c_last_name, ci.cd_gender, rs.ws_item_sk, id.i_item_desc, id.i_current_price
ORDER BY 
    total_net_profit DESC NULLS LAST
LIMIT 10;