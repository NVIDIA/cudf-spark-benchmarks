
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
    HAVING 
        SUM(cr_return_quantity) > 10
),
MaxReturns AS (
    SELECT 
        cr_returning_customer_sk,
        MAX(total_returned) AS max_return_quantity
    FROM 
        CustomerReturns
    GROUP BY 
        cr_returning_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    MAX(mr.max_return_quantity) AS max_return_contributed
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    MaxReturns mr ON c.c_customer_sk = mr.cr_returning_customer_sk
WHERE 
    c.c_birth_month = 12 
    AND ws.ws_sold_date_sk IS NOT NULL
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_net_profit DESC
LIMIT 10;

