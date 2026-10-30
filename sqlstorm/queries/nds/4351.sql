
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 0
),
ReturnStatistics AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_returned_date_sk) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tr.return_count,
        COALESCE(tr.total_returns, 0) AS total_returns,
        tc.sales_rank
    FROM 
        TopCustomers tc
    LEFT JOIN 
        ReturnStatistics tr ON tc.c_customer_sk = tr.sr_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.total_sales,
    cd.return_count,
    cd.total_returns,
    CASE 
        WHEN cd.total_sales > 0 THEN (cd.total_returns / cd.total_sales) * 100 
        ELSE NULL 
    END AS return_rate,
    CASE 
        WHEN cd.return_count > 0 THEN 'Returning Customer' 
        ELSE 'New Customer' 
    END AS customer_type
FROM 
    CustomerDetails cd
WHERE 
    cd.sales_rank <= 10
ORDER BY 
    cd.total_sales DESC;
