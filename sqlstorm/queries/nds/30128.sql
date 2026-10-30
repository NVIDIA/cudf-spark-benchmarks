
WITH  SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        ws.ws_ship_date_sk
),
TopSales AS (
    SELECT 
        ss.ws_ship_date_sk,
        ss.total_quantity,
        ss.total_sales,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary ss
    WHERE 
        ss.total_quantity > 100
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FinalReport AS (
    SELECT 
        d.d_date,
        ts.total_quantity,
        ts.total_sales,
        cr.return_count,
        cr.total_return_amt,
        CASE 
            WHEN cr.total_return_amt IS NULL THEN 'No Returns'
            WHEN cr.total_return_amt > 0 THEN 'Returned'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        TopSales ts
    JOIN 
        date_dim d ON ts.ws_ship_date_sk = d.d_date_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.c_customer_sk = (SELECT MAX(c.c_customer_sk) FROM customer c WHERE c.c_current_addr_sk IS NOT NULL)
    WHERE 
        ts.sales_rank <= 10
)
SELECT 
    f.d_date,
    f.total_quantity,
    f.total_sales,
    f.return_count,
    f.total_return_amt,
    f.return_status
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC;
