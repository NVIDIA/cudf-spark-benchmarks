
WITH CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        AVG(sr_return_ship_cost) AS average_ship_cost
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales_amount,
        SUM(ws_ext_discount_amt) AS total_discounted_amount,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemsSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(cr.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS returned_amount,
        sd.total_orders,
        sd.total_sales_amount,
        sd.total_discounted_amount,
        sd.total_net_profit,
        (CASE 
            WHEN sd.total_sales_amount > 0 THEN 
                ROUND((COALESCE(cr.total_returned_amount, 0) / sd.total_sales_amount) * 100, 2)
            ELSE 0
        END) AS return_percentage
    FROM 
        item i
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    i.i_item_desc AS item_description,
    i.returned_quantity,
    i.returned_amount,
    i.total_orders,
    i.total_sales_amount,
    i.total_discounted_amount,
    i.total_net_profit,
    i.return_percentage
FROM 
    ItemsSummary i
WHERE 
    i.return_percentage > 5
ORDER BY 
    i.return_percentage DESC
LIMIT 10;
