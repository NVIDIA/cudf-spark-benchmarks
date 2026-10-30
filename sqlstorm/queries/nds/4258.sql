
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_net_loss) AS total_loss
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number, wr.wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        COALESCE(SUM(r.ws_net_profit), 0) AS total_sales_profit,
        COALESCE(SUM(c.total_returned), 0) AS total_returns,
        COALESCE(SUM(c.total_loss), 0) AS total_loss
    FROM 
        web_sales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_order_number = c.wr_order_number AND r.ws_item_sk = c.wr_item_sk
    GROUP BY 
        r.ws_order_number, r.ws_item_sk
),
FinalResults AS (
    SELECT 
        sar.ws_order_number,
        sar.ws_item_sk,
        sar.total_sales_profit,
        sar.total_returns,
        sar.total_loss,
        (sar.total_sales_profit - sar.total_loss) AS net_profit_loss
    FROM 
        SalesAndReturns sar
    WHERE 
        sar.total_sales_profit > 0
)
SELECT 
    f.ws_order_number,
    f.ws_item_sk,
    f.total_sales_profit,
    f.total_returns,
    f.total_loss,
    f.net_profit_loss,
    CASE 
        WHEN f.net_profit_loss > 0 THEN 'Profitable'
        WHEN f.net_profit_loss < 0 THEN 'Loss'
        ELSE 'Break-even' 
    END AS profit_status
FROM 
    FinalResults f
WHERE 
    f.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 50)
ORDER BY 
    f.net_profit_loss DESC
LIMIT 100;
