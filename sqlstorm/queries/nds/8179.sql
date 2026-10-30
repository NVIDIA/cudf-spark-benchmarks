
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND ws.ws_ship_date_sk BETWEEN 10101 AND 10131
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    SUM(rs.ws_quantity) AS total_sold,
    SUM(rs.ws_net_profit) AS total_net_profit,
    ar.total_return_quantity,
    ar.total_return_amount
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    AggregatedReturns ar ON i.i_item_sk = ar.sr_item_sk
WHERE 
    rs.rank = 1
GROUP BY 
    i.i_item_id, i.i_item_desc, ar.total_return_quantity, ar.total_return_amount
ORDER BY 
    total_net_profit DESC
LIMIT 10;
