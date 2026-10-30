
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_sales_amt,
        AVG(ws_sales_price) AS avg_price
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
), TopCustomers AS (
    SELECT 
        c.c_customer_id,
        COALESCE(CR.return_count, 0) AS return_count,
        COALESCE(WS.order_count, 0) AS order_count,
        WS.total_sales_amt,
        CR.total_return_amt,
        CASE 
            WHEN WS.total_sales_amt > 0 THEN (CR.total_return_amt / WS.total_sales_amt) * 100
            ELSE NULL 
        END AS return_rate
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns CR ON c.c_customer_sk = CR.sr_customer_sk
    LEFT JOIN 
        WebSalesSummary WS ON c.c_customer_sk = WS.ws_bill_customer_sk
)
SELECT 
    TC.c_customer_id,
    TC.return_count,
    TC.order_count,
    TC.total_sales_amt,
    TC.total_return_amt,
    CASE 
        WHEN TC.order_count < 5 THEN 'Low Engagement'
        WHEN TC.order_count BETWEEN 5 AND 15 THEN 'Moderate Engagement'
        ELSE 'High Engagement'
    END AS engagement_level,
    TC.return_rate,
    CASE 
        WHEN TC.return_rate IS NULL THEN 'No Sales'
        WHEN TC.return_rate > 20 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_category
FROM 
    TopCustomers TC
WHERE 
    TC.total_sales_amt > 1000
ORDER BY 
    TC.total_sales_amt DESC
LIMIT 10;
