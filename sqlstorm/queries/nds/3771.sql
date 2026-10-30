
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS return_count, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales_amt,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450590  
    GROUP BY 
        ws_bill_customer_sk
),
ExpectedReturnRate AS (
    SELECT 
        S.ws_bill_customer_sk AS cs_bill_customer_sk, 
        COALESCE(SUM(CASE WHEN C.return_count IS NOT NULL THEN C.return_count ELSE 0 END), 0) AS expected_returns
    FROM 
        SalesData S
    LEFT JOIN 
        CustomerReturns C ON S.ws_bill_customer_sk = C.sr_customer_sk
    GROUP BY 
        S.ws_bill_customer_sk
),
FinalResult AS (
    SELECT 
        S.ws_bill_customer_sk,
        S.total_sales_amt,
        S.total_orders,
        S.avg_sales_price,
        E.expected_returns,
        CASE 
            WHEN E.expected_returns > 0 THEN 'High Risk'
            ELSE 'Low Risk'
        END AS return_risk_level
    FROM 
        SalesData S
    LEFT JOIN 
        ExpectedReturnRate E ON S.ws_bill_customer_sk = E.cs_bill_customer_sk
)
SELECT 
    C.c_first_name,
    C.c_last_name,
    F.total_sales_amt,
    F.total_orders,
    F.avg_sales_price,
    F.expected_returns,
    F.return_risk_level
FROM 
    FinalResult F
JOIN 
    customer C ON F.ws_bill_customer_sk = C.c_customer_sk
WHERE 
    C.c_current_addr_sk IS NOT NULL
    AND C.c_preferred_cust_flag = 'Y'
ORDER BY 
    F.total_sales_amt DESC
LIMIT 50;
