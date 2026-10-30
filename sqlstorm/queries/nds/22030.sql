WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > (SELECT AVG(ws_net_paid) FROM web_sales) 
        AND ws.ws_ship_date_sk IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr.wr_order_number,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_returns,
        SUM(CASE WHEN wr.wr_reason_sk IS NOT NULL THEN wr.wr_return_quantity ELSE 0 END) AS returned_with_reason
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
)
SELECT 
    c.c_customer_id,
    ra.ws_order_number,
    ra.ws_item_sk,
    ra.ws_quantity,
    ra.ws_net_profit,
    cr.total_returns,
    cr.returned_with_reason,
    ca.ca_city,
    CASE 
        WHEN cr.returned_with_reason > 0 THEN 'Returned'
        WHEN cr.total_returns = 0 THEN 'No Returns'
        ELSE 'Unknown'
    END AS return_status,
    DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ra.ws_net_profit) DESC) AS customer_rank
FROM 
    customer c
JOIN 
    RankedSales ra ON c.c_customer_sk = ra.ws_item_sk  
LEFT JOIN 
    CustomerReturns cr ON ra.ws_order_number = cr.wr_order_number
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (ca.ca_state IN ('CA', 'TX') OR (ca.ca_country IS NULL AND ca.ca_zip IS NOT NULL))
    AND (cr.total_returns IS NULL OR cr.returned_with_reason <= cr.total_returns)
GROUP BY 
    c.c_customer_id, ra.ws_order_number, ra.ws_item_sk, ra.ws_quantity, ra.ws_net_profit, cr.total_returns, cr.returned_with_reason, ca.ca_city
HAVING 
    SUM(ra.ws_net_profit) > 500
ORDER BY 
    customer_rank, ra.ws_net_profit DESC;