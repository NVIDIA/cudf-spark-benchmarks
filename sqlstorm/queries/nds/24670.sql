
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_ticket_number) AS total_returns, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(cd.cd_gender, 'U') AS customer_gender
    FROM 
        item i
    LEFT JOIN 
        customer c ON i.i_item_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    id.customer_gender
FROM 
    ItemDetails id
LEFT JOIN 
    SalesData sd ON id.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON id.i_item_sk = cr.sr_item_sk
WHERE 
    COALESCE(sd.total_quantity, 0) > (SELECT AVG(total_quantity) FROM SalesData)
    OR 
    id.customer_gender = 'F'
ORDER BY 
    total_net_profit DESC,
    total_quantity_sold DESC;
