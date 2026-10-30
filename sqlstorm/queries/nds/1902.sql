
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
),
ReturnsSummary AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returned,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
CustomerNetSales AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales - COALESCE(rs.total_returned, 0) AS net_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        ReturnsSummary rs ON tc.c_customer_sk = rs.wr_returning_customer_sk
)
SELECT 
    cns.c_first_name,
    cns.c_last_name,
    cns.net_sales,
    CASE 
        WHEN cns.net_sales > 1000 THEN 'High Value'
        WHEN cns.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    CustomerNetSales cns
ORDER BY 
    cns.net_sales DESC
LIMIT 10;
