
WITH CTE_Sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
),
CTE_Returns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MAX(d.d_date_sk) 
                                    FROM date_dim d 
                                    WHERE d.d_year = 2023)
    GROUP BY 
        wr.wr_item_sk
),
CTE_Item_Summary AS (
    SELECT 
        c.i_item_sk,
        c.i_item_id,
        COALESCE(s.total_returned, 0) AS total_returned,
        COALESCE(s.total_return_amt, 0) AS total_return_amt,
        SUM(sales.ws_net_profit) AS total_net_profit
    FROM 
        item c
    LEFT JOIN 
        CTE_Returns s ON c.i_item_sk = s.wr_item_sk
    JOIN 
        CTE_Sales sales ON c.i_item_sk = sales.ws_item_sk
    GROUP BY 
        c.i_item_sk, c.i_item_id, s.total_returned, s.total_return_amt
)
SELECT 
    i.i_item_id,
    i.total_returned,
    i.total_return_amt,
    i.total_net_profit,
    (CASE 
         WHEN i.total_net_profit IS NULL OR i.total_net_profit = 0 THEN NULL 
         ELSE ROUND(i.total_return_amt * 100.0 / i.total_net_profit, 2) 
     END) AS return_percentage
FROM 
    CTE_Item_Summary i
WHERE 
    i.total_net_profit > 0
ORDER BY 
    return_percentage DESC
LIMIT 10;
