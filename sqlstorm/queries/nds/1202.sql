
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)
        )
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ts.total_quantity, 0) AS quantity_sold,
    COALESCE(ts.total_revenue, 0) AS revenue_generated,
    COALESCE(cr.total_returns, 0) AS returns_count,
    COALESCE(cr.total_returns, 0) * 100.0 / NULLIF(COALESCE(ts.total_quantity, 0), 0) AS return_rate_percentage
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
WHERE 
    i.i_current_price > 0
ORDER BY 
    return_rate_percentage DESC;
