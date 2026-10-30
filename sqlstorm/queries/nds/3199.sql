
WITH CustomerReturns AS (
    SELECT 
        sr_item_sk,
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, 
        sr_returned_date_sk
),
HighReturningItems AS (
    SELECT 
        cr.sr_item_sk,
        COALESCE(SUM(cr.total_returned_quantity), 0) AS total_quantity_returned,
        COALESCE(SUM(cr.total_returned_amt), 0) AS total_amount_returned
    FROM 
        CustomerReturns cr
    GROUP BY 
        cr.sr_item_sk
    HAVING 
        SUM(cr.total_returned_quantity) > 100
),
WebSalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        HighReturningItems hri ON ws.ws_item_sk = hri.sr_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws.ws_item_sk
),
RankedSales AS (
    SELECT 
        wss.ws_item_sk,
        wss.total_orders,
        wss.total_net_profit,
        RANK() OVER (ORDER BY wss.total_net_profit DESC) AS sales_rank
    FROM 
        WebSalesSummary wss
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    r.sales_rank,
    r.total_orders,
    r.total_net_profit,
    COALESCE(ca.ca_city, 'Unknown') AS city
FROM 
    RankedSales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer_address ca ON i.i_item_sk = ca.ca_address_sk
WHERE 
    (r.total_net_profit IS NOT NULL AND r.total_net_profit > 0)
ORDER BY 
    r.sales_rank
LIMIT 10;
