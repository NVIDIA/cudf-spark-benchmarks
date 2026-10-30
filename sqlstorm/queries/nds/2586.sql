
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
AggregatedReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS Total_Returns,
        SUM(wr.wr_return_amt_inc_tax) AS Total_Return_Value
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_profit,
        COALESCE(ar.Total_Returns, 0) AS Total_Returns,
        COALESCE(ar.Total_Return_Value, 0) AS Total_Return_Value,
        rs.Rank
    FROM 
        RankedSales rs
    LEFT JOIN 
        AggregatedReturns ar ON rs.ws_item_sk = ar.wr_item_sk
)
SELECT 
    s.ws_order_number,
    s.ws_item_sk,
    s.ws_quantity,
    s.ws_net_profit,
    s.Total_Returns,
    s.Total_Return_Value,
    (s.ws_net_profit - s.Total_Return_Value) AS Adjusted_Net_Profit
FROM 
    SalesAndReturns s
WHERE 
    s.Rank = 1
ORDER BY 
    Adjusted_Net_Profit DESC
LIMIT 10;
