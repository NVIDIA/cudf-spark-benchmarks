
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
SalesReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        sr.sr_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_revenue,
        COALESCE(sr.total_returns, 0) AS total_returns,
        (ri.total_revenue - COALESCE(sr.total_returns, 0) * 10) AS net_revenue
    FROM 
        RankedSales ri
    LEFT JOIN 
        SalesReturns sr ON ri.ws_item_sk = sr.sr_item_sk
    WHERE 
        ri.revenue_rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_revenue,
    ti.total_returns,
    ti.net_revenue,
    CASE 
        WHEN ti.net_revenue < 0 THEN 'Loss'
        WHEN ti.net_revenue = 0 THEN 'Break-even'
        ELSE 'Profit'
    END AS financial_status
FROM 
    TopItems ti
ORDER BY 
    ti.net_revenue DESC;
