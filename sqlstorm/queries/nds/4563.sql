
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        ws_sold_date_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_sold_date_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        ca.ca_country,
        SUM(ss.total_sales) AS annual_sales,
        COUNT(ss.total_quantity) AS total_orders
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ss.sales_rank <= 10 AND ca.ca_country IS NOT NULL
    GROUP BY 
        c.c_customer_id, ca.ca_country
),
MonthlyReturns AS (
    SELECT 
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk
)
SELECT 
    tc.c_customer_id,
    tc.ca_country,
    tc.annual_sales,
    tc.total_orders,
    COALESCE(mr.total_returned_amt, 0) AS total_returned_amt,
    COALESCE(mr.total_returns, 0) AS total_returns,
    (tc.annual_sales - COALESCE(mr.total_returned_amt, 0)) AS net_sales,
    CASE 
        WHEN tc.total_orders > 0 THEN ROUND((COALESCE(mr.total_returns, 0) * 1.0 / tc.total_orders) * 100, 2)
        ELSE NULL 
    END AS return_percentage
FROM 
    TopCustomers tc
LEFT JOIN 
    MonthlyReturns mr ON mr.wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
ORDER BY 
    net_sales DESC
LIMIT 50;
