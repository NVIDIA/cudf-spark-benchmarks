
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
avg_sales AS (
    SELECT 
        sd.ws_item_sk,
        AVG(sd.total_sales) AS avg_sales,
        AVG(sd.total_profit) AS avg_profit
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        a.avg_sales,
        a.avg_profit
    FROM 
        avg_sales a
    JOIN 
        item i ON a.ws_item_sk = i.i_item_sk
    WHERE 
        a.avg_sales > (SELECT AVG(avg_sales) FROM avg_sales)
    ORDER BY 
        a.avg_sales DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.avg_sales,
    ti.avg_profit
FROM 
    top_items ti
JOIN 
    customer_demographics cd ON cd.cd_demo_sk IN 
        (SELECT c.c_current_cdemo_sk FROM customer c 
         WHERE c.c_current_cdemo_sk IS NOT NULL)
ORDER BY 
    ti.avg_profit DESC;
