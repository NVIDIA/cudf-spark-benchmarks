
WITH sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand
    FROM 
        item
),
sales_data AS (
    SELECT 
        ss.ws_ship_date_sk,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_profit,
        id.i_item_desc,
        id.i_current_price,
        id.i_brand
    FROM 
        sales_summary ss
    JOIN 
        item_details id ON ss.ws_item_sk = id.i_item_sk
),
date_info AS (
    SELECT 
        d_date_sk,
        d_year,
        d_month_seq,
        d_day_name
    FROM 
        date_dim
)
SELECT 
    di.d_year,
    di.d_month_seq,
    di.d_day_name,
    sd.i_brand,
    SUM(sd.total_quantity) AS total_quantity_sold,
    SUM(sd.total_net_profit) AS total_net_profit
FROM 
    sales_data sd
JOIN 
    date_info di ON sd.ws_ship_date_sk = di.d_date_sk
GROUP BY 
    di.d_year, di.d_month_seq, di.d_day_name, sd.i_brand
ORDER BY 
    di.d_year, di.d_month_seq, total_net_profit DESC;
