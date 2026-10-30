WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451936 AND 2452000 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ProfitData AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_profit,
        CASE 
            WHEN sd.total_profit > 0 THEN 'Profitable'
            WHEN sd.total_profit < 0 THEN 'Unprofitable'
            ELSE 'Break-even'
        END AS profitability_status
    FROM 
        SalesData sd
),
TopItems AS (
    SELECT 
        pd.ws_item_sk,
        pd.total_sales,
        pd.total_profit,
        pd.profitability_status,
        RANK() OVER (PARTITION BY pd.profitability_status ORDER BY pd.total_profit DESC) AS rank
    FROM 
        ProfitData pd
)
SELECT 
    ti.ws_item_sk,
    ti.total_sales,
    ti.total_profit,
    ti.profitability_status
FROM 
    TopItems ti
WHERE 
    ti.rank <= 5
ORDER BY 
    ti.profitability_status, ti.total_profit DESC;