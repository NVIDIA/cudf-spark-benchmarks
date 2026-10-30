
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.*,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
TopSales AS (
    SELECT 
        csr.c_customer_sk,
        csr.c_first_name,
        csr.c_last_name,
        csr.total_sales,
        csr.order_count,
        COALESCE(COUNT(DISTINCT wr.wr_order_number), 0) AS total_web_returns,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amount
    FROM 
        SalesRanked csr
    LEFT JOIN 
        web_returns wr ON csr.c_customer_sk = wr.wr_returning_customer_sk
    WHERE 
        sales_rank <= 10
    GROUP BY 
        csr.c_customer_sk, csr.c_first_name, csr.c_last_name, csr.total_sales, csr.order_count
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    t.total_web_returns,
    t.total_return_amount,
    CASE 
        WHEN t.total_sales > 1000 THEN 'VIP'
        WHEN t.total_sales BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'New'
    END AS customer_status
FROM 
    TopSales t
ORDER BY 
    t.total_sales DESC;
