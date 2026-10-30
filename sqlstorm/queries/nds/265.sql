WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ris.ws_item_sk,
        i.i_item_id,
        i.i_product_name,
        ris.total_quantity,
        ris.total_net_paid
    FROM 
        RankedSales ris
    JOIN 
        item i ON ris.ws_item_sk = i.i_item_sk
    WHERE 
        ris.rank <= 10
),
SalesByMonth AS (
    SELECT 
        d.d_month_seq,
        SUM(ts.total_net_paid) AS month_total
    FROM 
        TopItems ts
    JOIN 
        date_dim d ON d.d_date_sk = ts.total_net_paid 
    GROUP BY 
        d.d_month_seq
),
MonthlyGrowth AS (
    SELECT 
        b.d_month_seq,
        b.month_total,
        COALESCE((b.month_total - a.month_total) / NULLIF(a.month_total, 0), 0) AS growth_rate
    FROM 
        SalesByMonth a
    FULL OUTER JOIN
        SalesByMonth b ON a.d_month_seq = b.d_month_seq + 1
)
SELECT 
    m.d_month_seq,
    m.month_total,
    m.growth_rate,
    CASE 
        WHEN m.growth_rate > 0 THEN 'Increase'
        WHEN m.growth_rate < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS growth_status
FROM 
    MonthlyGrowth m
WHERE 
    m.d_month_seq IS NOT NULL
ORDER BY 
    m.d_month_seq DESC;