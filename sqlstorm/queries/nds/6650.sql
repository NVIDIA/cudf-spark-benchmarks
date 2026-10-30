
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
WebSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CombinedSales AS (
    SELECT 
        COALESCE(CR.sr_returned_date_sk, WS.ws_sold_date_sk) AS report_date,
        COALESCE(CR.sr_item_sk, WS.ws_item_sk) AS item_sk,
        COALESCE(total_sold_quantity, 0) AS total_sold_quantity,
        COALESCE(total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(total_profit, 0) AS total_profit
    FROM 
        WebSales WS
    FULL OUTER JOIN 
        CustomerReturns CR ON WS.ws_sold_date_sk = CR.sr_returned_date_sk AND WS.ws_item_sk = CR.sr_item_sk
)
SELECT 
    C.item_sk,
    C.report_date,
    C.total_sold_quantity,
    C.total_returned_quantity,
    C.total_profit,
    (C.total_sold_quantity - C.total_returned_quantity) AS net_sales,
    (C.total_profit / NULLIF(C.total_sold_quantity, 0)) AS avg_profit_per_sale
FROM 
    CombinedSales C
WHERE 
    C.report_date BETWEEN 20230101 AND 20231231
ORDER BY 
    C.report_date DESC, net_sales DESC
LIMIT 100;
