
WITH SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws.ws_ship_date_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_revenue
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim dd ON ws.ws_ship_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND
        i.i_current_price BETWEEN 10 AND 100
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_ship_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_revenue 
    FROM 
        SalesData sd
    WHERE 
        sd.rank_revenue <= 5
)
SELECT 
    dd.d_date,
    i.i_item_desc,
    t.total_quantity,
    t.total_revenue
FROM 
    TopSales t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
JOIN 
    date_dim dd ON t.ws_ship_date_sk = dd.d_date_sk
ORDER BY 
    dd.d_date, t.total_revenue DESC;
