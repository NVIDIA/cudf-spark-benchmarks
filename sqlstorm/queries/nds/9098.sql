
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND 
        dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT
        sd.ws_item_sk,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.profit_rank,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit
FROM 
    TopItems ti
JOIN 
    SalesData sd ON ti.ws_item_sk = sd.ws_item_sk
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
WHERE 
    ti.profit_rank <= 10
ORDER BY 
    ti.profit_rank;
