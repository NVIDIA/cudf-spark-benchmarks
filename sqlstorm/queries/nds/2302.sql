WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_net_profit) AS average_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_quantity) AS store_quantity_sold,
        SUM(s.ss_net_paid_inc_tax) AS store_revenue
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)))
    GROUP BY 
        s.ss_item_sk
),
Combined AS (
    SELECT 
        COALESCE(ss.ws_item_sk, ti.ss_item_sk) AS item_sk,
        COALESCE(ss.total_quantity_sold, 0) AS web_quantity_sold,
        COALESCE(ss.total_revenue, 0) AS web_revenue,
        COALESCE(ti.store_quantity_sold, 0) AS store_quantity_sold,
        COALESCE(ti.store_revenue, 0) AS store_revenue
    FROM 
        SalesSummary ss
    FULL OUTER JOIN 
        TopItems ti ON ss.ws_item_sk = ti.ss_item_sk
)
SELECT 
    c.i_item_id,
    c.i_item_desc,
    cb.web_quantity_sold,
    cb.web_revenue,
    cb.store_quantity_sold,
    cb.store_revenue,
    (cb.web_revenue + cb.store_revenue) AS total_revenue,
    (cb.web_revenue - cb.store_revenue) AS revenue_difference
FROM 
    Combined cb
JOIN 
    item c ON cb.item_sk = c.i_item_sk
WHERE 
    cb.web_revenue IS NOT NULL OR cb.store_revenue IS NOT NULL
ORDER BY 
    total_revenue DESC
LIMIT 10;