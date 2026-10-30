
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ris.ws_item_sk,
        ris.total_quantity,
        ris.total_net_profit,
        i.i_item_desc
    FROM 
        RankedSales ris
    JOIN 
        item i ON ris.ws_item_sk = i.i_item_sk
    WHERE 
        ris.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
PopularCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE 
        cr.total_returns > 0
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit,
    pc.c_first_name,
    pc.c_last_name,
    pc.total_returns,
    ROW_NUMBER() OVER (PARTITION BY ti.ws_item_sk ORDER BY pc.total_returns DESC) AS customer_rank
FROM 
    TopItems ti
LEFT JOIN 
    PopularCustomers pc ON ti.ws_item_sk = pc.sr_customer_sk
ORDER BY 
    ti.total_net_profit DESC, 
    pc.total_returns DESC;
