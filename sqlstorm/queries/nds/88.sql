
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        ws.ws_sold_date_sk
),
ReturnsSummary AS (
    SELECT 
        wr.wr_returned_date_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returned_date_sk
),
DailyPerformance AS (
    SELECT 
        dd.d_date_id,
        COALESCE(ss.total_quantity, 0) AS total_sales_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales_amount,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_return_amount, 0)) AS net_revenue
    FROM 
        date_dim dd
    LEFT JOIN 
        SalesSummary ss ON dd.d_date_sk = ss.ws_sold_date_sk
    LEFT JOIN 
        ReturnsSummary rs ON dd.d_date_sk = rs.wr_returned_date_sk
    WHERE 
        dd.d_year = 2023
),
RankedPerformance AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY net_revenue DESC) AS revenue_rank
    FROM 
        DailyPerformance
)
SELECT 
    d.d_date_id,
    d.total_sales_quantity,
    d.total_sales_amount,
    d.total_returns,
    d.total_return_amount,
    d.net_revenue,
    d.revenue_rank
FROM 
    RankedPerformance d
WHERE 
    d.revenue_rank <= 10
ORDER BY 
    d.net_revenue DESC;
