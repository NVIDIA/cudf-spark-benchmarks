
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
AggregatedSales AS (
    SELECT 
        ws_order_number AS order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM 
        SalesCTE
    GROUP BY 
        ws_order_number
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS returns_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
JoinCustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_profit,
        cr.returns_count,
        cr.total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        AggregatedSales cs ON c.c_customer_sk = cs.order_number
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.total_quantity, 0) AS total_quantity,
    COALESCE(cs.total_profit, 0) AS total_profit,
    COALESCE(cr.returns_count, 0) AS returns_count,
    COALESCE(cr.total_return_amt, 0.00) AS total_return_amt,
    CASE 
        WHEN COALESCE(cr.total_return_amt, 0) > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
FROM 
    customer c
LEFT JOIN 
    AggregatedSales cs ON cs.order_number = c.c_customer_sk
LEFT JOIN 
    CustomerReturns cr ON cr.sr_customer_sk = c.c_customer_sk
ORDER BY 
    total_profit DESC
LIMIT 100;
