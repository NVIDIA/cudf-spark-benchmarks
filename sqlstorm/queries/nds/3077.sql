
WITH SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year > 1980
),
TopSales AS (
    SELECT
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit
    FROM
        SalesData sd
    WHERE
        sd.rn <= 3
    GROUP BY
        sd.ws_order_number
),
ReturnedItems AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalReport AS (
    SELECT 
        ts.ws_order_number,
        ts.total_quantity,
        ts.total_profit,
        COALESCE(ri.total_returns, 0) AS total_returns
    FROM 
        TopSales ts
    LEFT JOIN 
        ReturnedItems ri ON ts.ws_order_number = ri.cr_item_sk
)
SELECT 
    fr.ws_order_number,
    fr.total_quantity,
    fr.total_profit,
    fr.total_returns,
    (fr.total_profit - fr.total_returns * 0.1) AS adjusted_profit
FROM 
    FinalReport fr
WHERE 
    fr.total_profit > 1000
ORDER BY 
    adjusted_profit DESC;
