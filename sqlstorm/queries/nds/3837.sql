
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS TotalReturns,
        SUM(sr_return_quantity) AS TotalReturnQty,
        SUM(sr_return_amt) AS TotalReturnAmt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerWebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS TotalWebSales,
        COUNT(DISTINCT ws_order_number) AS TotalWebOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomersWithReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.TotalReturns, 0) AS TotalReturns,
        COALESCE(cr.TotalReturnQty, 0) AS TotalReturnQty,
        COALESCE(cr.TotalReturnAmt, 0) AS TotalReturnAmt,
        COALESCE(ws.TotalWebSales, 0) AS TotalWebSales,
        COALESCE(ws.TotalWebOrders, 0) AS TotalWebOrders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        CustomerWebSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalWebSales DESC, TotalReturns DESC) AS SalesRank
    FROM 
        CustomersWithReturns
),
FinalReport AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS FullName, 
        c.TotalReturns, 
        c.TotalReturnQty,
        c.TotalReturnAmt,
        c.TotalWebSales,
        c.TotalWebOrders,
        CASE 
            WHEN c.TotalWebSales = 0 THEN 'No Sales'
            WHEN c.TotalReturns > 0 THEN 'Returned Items'
            ELSE 'Active Customer'
        END AS CustomerStatus
    FROM 
        RankedCustomers c
    WHERE 
        c.SalesRank <= 100
)
SELECT 
    f.FullName,
    f.TotalReturns,
    f.TotalReturnQty,
    f.TotalReturnAmt,
    f.TotalWebSales,
    f.TotalWebOrders,
    f.CustomerStatus
FROM 
    FinalReport f
ORDER BY 
    f.TotalWebSales DESC;
