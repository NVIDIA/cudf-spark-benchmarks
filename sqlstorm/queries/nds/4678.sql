
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
BestSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        i.i_product_name,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
)
SELECT 
    bi.ws_item_sk,
    bi.i_product_name,
    bi.total_quantity,
    bi.total_profit,
    CASE 
        WHEN bi.total_profit > 1000 THEN 'High Profit'
        WHEN bi.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM 
    BestSellingItems bi
WHERE 
    bi.profit_rank <= 10
ORDER BY 
    bi.total_profit DESC;
