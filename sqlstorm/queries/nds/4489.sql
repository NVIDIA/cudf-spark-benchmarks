WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
ReturnStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ss.c_customer_id,
    ss.total_sales,
    ss.order_count,
    rs.return_count,
    COALESCE(rs.total_returns, 0) AS total_returns,
    (ss.total_sales - COALESCE(rs.total_returns, 0)) AS net_sales
FROM 
    SalesSummary ss
LEFT JOIN 
    ReturnStats rs ON ss.c_customer_id = rs.c_customer_id
WHERE 
    ss.sales_rank <= 100 
    AND ss.total_sales > 1000 
ORDER BY 
    net_sales DESC;