
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
)
, CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_refunds
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(AVG(cs.cs_net_profit), 0) AS average_store_profit,
    COALESCE(SUM(CASE WHEN r.total_quantity > 100 THEN r.total_quantity ELSE 0 END), 0) AS high_selling_quantity,
    COALESCE(cr.total_returns, 0) AS total_item_returns,
    COALESCE(cr.total_refunds, 0) AS total_refund_amount,
    CASE 
        WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    item i
LEFT JOIN 
    (
        SELECT 
            cs.cs_item_sk,
            SUM(cs.cs_net_profit) AS cs_net_profit
        FROM 
            catalog_sales cs
        GROUP BY 
            cs.cs_item_sk
    ) cs ON i.i_item_sk = cs.cs_item_sk
LEFT JOIN 
    RankedSales r ON i.i_item_sk = r.ws_item_sk AND r.rank = 1
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE 
    (cr.total_returns IS NULL OR cr.total_returns < 5)
    AND (i.i_current_price BETWEEN 10 AND 100 OR i.i_current_price IS NULL)
GROUP BY 
    i.i_item_id, 
    i.i_item_desc, 
    cr.total_returns, 
    cr.total_refunds
HAVING 
    SUM(COALESCE(cs.cs_net_profit, 0)) > 1000
ORDER BY 
    average_store_profit DESC, 
    high_selling_quantity DESC;
