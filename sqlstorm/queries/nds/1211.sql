
WITH Ranked_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
Top_Selling_Items AS (
    SELECT 
        rsi.ws_item_sk,
        rsi.total_quantity,
        rsi.total_net_profit,
        i.i_product_name
    FROM 
        Ranked_Sales AS rsi
    JOIN 
        item AS i ON rsi.ws_item_sk = i.i_item_sk
    WHERE 
        rsi.rank <= 10
),
Customer_Returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
Return_Details AS (
    SELECT 
        tsi.i_product_name,
        tsi.total_quantity,
        COALESCE(cr.total_returned, 0) AS total_returned,
        tsi.total_net_profit
    FROM 
        Top_Selling_Items AS tsi
    LEFT JOIN 
        Customer_Returns AS cr ON tsi.ws_item_sk = cr.wr_item_sk
)
SELECT 
    rd.i_product_name,
    rd.total_quantity,
    rd.total_returned,
    rd.total_net_profit,
    CASE 
        WHEN rd.total_returned > 0 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM 
    Return_Details AS rd
WHERE 
    rd.total_net_profit > 1000
ORDER BY 
    rd.total_net_profit DESC;
