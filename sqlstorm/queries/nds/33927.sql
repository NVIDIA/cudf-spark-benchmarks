
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 3000
    GROUP BY 
        ws_item_sk
),
customer_returns AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_refund
    FROM 
        catalog_returns
    WHERE 
        cr_returning_customer_sk IS NOT NULL
    GROUP BY 
        cr_item_sk
),
return_stats AS (
    SELECT 
        sd.ws_item_sk,
        sd.order_count,
        sd.total_profit,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_refund, 0) AS total_refund,
        CASE 
            WHEN sd.total_profit > 0 THEN (COALESCE(cr.total_refund, 0) / sd.total_profit) * 100
            ELSE 0
        END AS refund_percentage
    FROM 
        sales_data sd
    LEFT JOIN 
        customer_returns cr ON sd.ws_item_sk = cr.cr_item_sk
)
SELECT 
    r.ws_item_sk,
    r.order_count,
    r.total_profit,
    r.return_count,
    r.total_refund,
    r.refund_percentage
FROM 
    return_stats r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    (r.return_count > 0 OR r.refund_percentage > 10)
    AND i.i_current_price > 20.00
ORDER BY 
    r.refund_percentage DESC
LIMIT 10;
