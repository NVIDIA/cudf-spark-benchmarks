
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    r.ws_item_sk,
    i.i_product_name,
    r.total_quantity,
    r.total_net_profit,
    r.profit_rank
FROM 
    RankedSales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.total_net_profit DESC;
