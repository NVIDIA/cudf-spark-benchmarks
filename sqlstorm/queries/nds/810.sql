
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
ReturnDetails AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    hv.c_first_name,
    hv.c_last_name,
    hv.total_sales,
    hv.order_count,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    COALESCE(rd.return_count, 0) AS return_count,
    CASE 
        WHEN COALESCE(rd.total_return_amt, 0) > hv.total_sales * 0.1 THEN 'High Return'
        ELSE 'Low Return' 
    END AS return_category
FROM 
    HighValueCustomers hv
LEFT JOIN 
    ReturnDetails rd ON hv.c_customer_sk = rd.wr_returning_customer_sk
ORDER BY 
    hv.total_sales DESC;
