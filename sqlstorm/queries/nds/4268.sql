
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
CustomerGenderCount AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RS.total_net_profit, 0) AS total_net_profit,
    COALESCE(TR.total_returned_quantity, 0) AS total_returned_quantity,
    CGC.customer_count AS customer_count_by_gender,
    (CASE 
        WHEN RS.total_net_profit IS NULL THEN 'No Sales'
        WHEN TR.total_returned_quantity > 0 THEN 'Returned'
        ELSE 'Sold'
    END) AS sales_status
FROM 
    item i
LEFT JOIN 
    (SELECT 
        r.ws_item_sk,
        SUM(r.ws_net_profit) AS total_net_profit
     FROM 
        web_sales r
     GROUP BY 
        r.ws_item_sk) RS ON i.i_item_sk = RS.ws_item_sk
LEFT JOIN 
    TotalReturns TR ON i.i_item_sk = TR.wr_item_sk
LEFT JOIN 
    CustomerGenderCount CGC ON CGC.cd_gender = (SELECT cd.cd_gender FROM customer_demographics cd WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = (SELECT DISTINCT c2.c_customer_sk FROM customer c2 WHERE c2.c_current_cdemo_sk IS NOT NULL LIMIT 1) LIMIT 1))
WHERE 
    (i.i_current_price * 100) - (COALESCE(TR.total_returned_quantity * 30.00, 0)) > 0
ORDER BY 
    i.i_item_id;
