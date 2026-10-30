WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
        SUM(wr.wr_return_quantity) AS total_web_return_qty
    FROM
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RecentSales AS (
    SELECT
        ws.ws_ship_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_date = cast('2002-10-01' as date) - INTERVAL '30' DAY
        )
    GROUP BY 
        ws.ws_ship_customer_sk
),
FinalReport AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        COALESCE(rs.total_sales, 0) AS total_sales_last_30_days,
        cr.total_web_returns,
        cr.total_web_return_amount,
        cr.total_web_return_qty
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        RecentSales rs ON cr.c_customer_sk = rs.ws_ship_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales_last_30_days,
    f.total_web_returns,
    f.total_web_return_amount,
    f.total_web_return_qty,
    CASE 
        WHEN f.total_web_return_amount > 1000 THEN 'High Return Value'
        WHEN f.total_web_returns > 10 THEN 'Frequent Returner'
        ELSE 'Normal Customer'
    END AS customer_category
FROM 
    FinalReport f
WHERE 
    f.total_web_return_qty > 0 OR f.total_sales_last_30_days > 0
ORDER BY 
    f.total_web_return_amount DESC, f.total_sales_last_30_days DESC;