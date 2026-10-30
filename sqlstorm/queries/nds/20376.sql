
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_per_item
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        LPAD(CAST(i.i_item_sk AS STRING), 10, '0') AS padded_item_sk,
        COALESCE(i.i_brand, 'Unknown') AS brand,
        COALESCE(NULLIF(i.i_color, ''), 'No Color') AS color
    FROM 
        item i
),
top_sales AS (
    SELECT 
        sd.*, 
        id.i_item_desc, 
        id.padded_item_sk, 
        id.brand, 
        id.color
    FROM 
        sales_data sd
    LEFT JOIN 
        item_details id ON sd.ws_item_sk = id.i_item_sk
    WHERE 
        sd.rank_per_item <= 5
)
SELECT 
    ts.padded_item_sk,
    ts.i_item_desc,
    ts.brand,
    ts.color,
    ts.total_quantity,
    ts.avg_sales_price,
    CASE 
        WHEN ts.total_net_paid > (SELECT AVG(total_net_paid) FROM top_sales) THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS net_paid_comparison,
    RANK() OVER (ORDER BY ts.total_quantity DESC) AS quantity_rank
FROM 
    top_sales ts
ORDER BY 
    ts.total_quantity DESC, 
    ts.avg_sales_price DESC;
