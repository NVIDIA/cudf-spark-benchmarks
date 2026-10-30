
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        sd.avg_net_paid,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_quantity > 100
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit,
    ti.avg_net_paid,
    d.d_date
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ti.ws_item_sk = d.d_date_sk
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_net_profit DESC;
