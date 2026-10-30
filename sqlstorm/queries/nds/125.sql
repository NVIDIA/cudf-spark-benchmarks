
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 0
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerReturns AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt
    FROM 
        TopCustomers tc
    LEFT JOIN 
        ReturnStats rs ON tc.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.total_sales,
    cr.return_count,
    cr.total_return_amt,
    (cr.total_sales - cr.total_return_amt) AS net_sales,
    CASE 
        WHEN cr.return_count > 0 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS customer_risk_category
FROM 
    CustomerReturns cr
WHERE 
    (cr.total_sales - cr.total_return_amt) > 1000
ORDER BY 
    cr.total_sales DESC
LIMIT 100;
