
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        MAX(ws.ws_net_profit) AS max_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        ws.ws_sold_date_sk BETWEEN 2459918 AND 2459890
    GROUP BY 
        ws.ws_sold_date_sk
),
DailyReturns AS (
    SELECT 
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr.wr_returned_date_sk
),
CombinedResults AS (
    SELECT 
        ds.d_date AS sale_date,
        ss.total_sales,
        ss.order_count,
        ss.avg_net_paid,
        r.total_return_amt,
        r.return_count
    FROM 
        SalesSummary ss
    JOIN 
        date_dim ds ON ss.ws_sold_date_sk = ds.d_date_sk
    LEFT JOIN 
        DailyReturns r ON ss.ws_sold_date_sk = r.wr_returned_date_sk
)
SELECT 
    sale_date,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(avg_net_paid, 0) AS avg_net_paid,
    COALESCE(total_return_amt, 0) AS total_return_amt,
    COALESCE(return_count, 0) AS return_count,
    (COALESCE(total_sales, 0) - COALESCE(total_return_amt, 0)) AS net_sales
FROM 
    CombinedResults
WHERE 
    (COALESCE(total_sales, 0) - COALESCE(total_return_amt, 0)) > 1000
ORDER BY 
    net_sales DESC;
