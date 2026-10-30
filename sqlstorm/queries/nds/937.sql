
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs 
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
FrequentReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        COALESCE(fr.return_count, 0) AS return_count,
        CASE 
            WHEN COALESCE(fr.return_count, 0) > 5 THEN 'High Return'
            ELSE 'Normal' 
        END AS return_status
    FROM 
        TopCustomers tc
    LEFT JOIN 
        FrequentReturns fr ON tc.c_customer_sk = fr.wr_returning_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name || ' ' || f.c_last_name AS customer_name,
    f.total_sales,
    f.return_count,
    f.return_status
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC, 
    f.return_count ASC;
