
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebsalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS order_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        C.c_customer_sk, 
        C.c_first_name, 
        C.c_last_name,
        COALESCE(CR.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(CR.total_returned_amount, 0) AS total_returned_amount,
        WS.total_orders, 
        WS.total_spent
    FROM 
        customer C
    LEFT JOIN 
        CustomerReturns CR ON C.c_customer_sk = CR.sr_customer_sk
    LEFT JOIN 
        WebsalesData WS ON C.c_customer_sk = WS.ws_bill_customer_sk
    WHERE 
        (CR.total_returned_quantity IS NULL OR CR.total_returned_quantity < 5) 
        AND (WS.total_spent > 1000 OR WS.total_orders IS NULL)
)
SELECT 
    TC.c_customer_sk, 
    TC.c_first_name, 
    TC.c_last_name, 
    TC.total_returned_quantity,
    TC.total_returned_amount,
    TC.total_orders,
    TC.total_spent,
    CASE 
        WHEN TC.total_spent IS NULL THEN 'No Orders'
        WHEN TC.total_returned_quantity = 0 THEN 'No Returns'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    TopCustomers TC
ORDER BY 
    TC.total_spent DESC
LIMIT 10;
