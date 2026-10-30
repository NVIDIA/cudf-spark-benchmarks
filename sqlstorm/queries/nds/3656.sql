
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.return_count,
        cr.total_return_amt
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.return_count > 5
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        sd.total_net_profit,
        sd.total_quantity_sold
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_net_profit, 0) AS total_net_profit,
    COALESCE(cs.total_quantity_sold, 0) AS total_quantity_sold,
    CASE 
        WHEN cs.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status,
    (SELECT COUNT(DISTINCT sr_item_sk) 
     FROM store_returns 
     WHERE sr_customer_sk = cs.c_customer_sk) AS distinct_returned_items,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cs.total_net_profit, 0) DESC) AS ranking
FROM 
    CustomerSales cs
ORDER BY 
    total_net_profit DESC;
