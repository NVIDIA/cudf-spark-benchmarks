
WITH Sales_CTE AS (
    SELECT 
        COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk) AS sold_date,
        COALESCE(ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
        COALESCE(ss.ss_net_paid, ws.ws_net_paid) AS net_paid,
        CASE 
            WHEN ss.ss_item_sk IS NOT NULL THEN 'Store Sales'
            WHEN ws.ws_item_sk IS NOT NULL THEN 'Web Sales'
            ELSE 'Unknown'
        END AS sales_channel,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ss.ss_item_sk, ws.ws_item_sk) ORDER BY COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk) DESC) AS rn
    FROM 
        store_sales ss
    FULL OUTER JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
    WHERE 
        (ss.ss_sold_date_sk IS NOT NULL OR ws.ws_sold_date_sk IS NOT NULL)
        AND (ss.ss_net_paid > 50 OR ws.ws_net_paid > 50)
),
Aggregate_Sales AS (
    SELECT 
        sold_date,
        item_sk,
        SUM(net_paid) AS total_net_paid,
        COUNT(*) AS sales_count,
        AVG(net_paid) AS avg_net_paid
    FROM 
        Sales_CTE
    GROUP BY 
        sold_date, 
        item_sk
)
SELECT 
    d.d_date AS sale_date,
    a.item_sk,
    a.total_net_paid,
    a.sales_count,
    a.avg_net_paid,
    RANK() OVER (PARTITION BY d.d_date ORDER BY a.total_net_paid DESC) AS rank_by_revenue
FROM 
    Aggregate_Sales a
JOIN 
    date_dim d ON d.d_date_sk = a.sold_date
WHERE 
    d.d_year = 2023
    AND (a.total_net_paid IS NOT NULL AND a.total_net_paid > (SELECT AVG(total_net_paid) FROM Aggregate_Sales))
    OR (a.sales_count > 5 AND a.avg_net_paid IS NOT NULL)
ORDER BY 
    sale_date, 
    rank_by_revenue
LIMIT 100 OFFSET 50;
