WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_products AS (
    SELECT 
        rs.ws_item_sk, 
        i.i_item_desc,
        rs.total_quantity_sold,
        rs.total_net_profit,
        i.i_current_price
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_profit <= 10
),
sales_data AS (
    SELECT 
        tp.ws_item_sk,
        tp.i_item_desc,
        tp.total_quantity_sold,
        tp.total_net_profit,
        tp.i_current_price,
        COALESCE(NULLIF(AVG(ws.ws_net_paid), 0), 1) AS avg_net_paid
    FROM 
        top_products tp
    LEFT JOIN 
        web_sales ws ON tp.ws_item_sk = ws.ws_item_sk
    GROUP BY 
        tp.ws_item_sk, tp.i_item_desc, tp.total_quantity_sold, tp.total_net_profit, tp.i_current_price
),
income_bracket AS (
    SELECT 
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
            WHEN hd.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_category,
        SUM(sd.total_net_profit) AS total_profit
    FROM 
        household_demographics hd
    JOIN 
        sales_data sd ON hd.hd_demo_sk = sd.ws_item_sk 
    GROUP BY 
        income_category
)
SELECT 
    ib.income_category,
    ib.total_profit,
    RANK() OVER (ORDER BY ib.total_profit DESC) AS income_rank
FROM 
    income_bracket ib
WHERE 
    ib.total_profit IS NOT NULL
ORDER BY 
    ib.total_profit DESC;