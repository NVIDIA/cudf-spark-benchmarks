
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year AS year, 
        d.d_month_seq AS month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_quantity DESC) AS quantity_rank,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity,
    tsi.total_net_profit,
    tsi.quantity_rank,
    tsi.profit_rank
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
WHERE 
    tsi.quantity_rank <= 10 OR tsi.profit_rank <= 10
ORDER BY 
    tsi.total_net_profit DESC;
