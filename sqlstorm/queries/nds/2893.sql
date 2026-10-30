
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.total_net_profit,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        r.rank <= 5
),
StoreReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemProfits AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
)
SELECT 
    tp.ws_bill_customer_sk,
    tp.c_first_name,
    tp.c_last_name,
    tp.ca_city,
    tp.ca_state,
    ip.i_product_name,
    ip.total_profit,
    COALESCE(sr.total_returns, 0) AS total_returns,
    ROUND((ip.total_profit - COALESCE(sr.total_returns, 0)), 2) AS net_profit_after_returns
FROM 
    TopCustomers tp
LEFT JOIN 
    ItemProfits ip ON tp.ws_bill_customer_sk = ip.i_item_sk
LEFT JOIN 
    StoreReturns sr ON ip.i_item_sk = sr.sr_item_sk
WHERE 
    tp.total_net_profit > 1000 
    AND tp.ca_city IS NOT NULL
ORDER BY 
    net_profit_after_returns DESC;
