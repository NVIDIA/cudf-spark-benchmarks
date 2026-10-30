
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
        CASE
            WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS customer_status
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_Most_Returned AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING COUNT(*) > (
        SELECT AVG(return_count)
        FROM (
            SELECT COUNT(*) AS return_count 
            FROM store_returns 
            GROUP BY sr_item_sk
        ) AS avg_returns
    )
),
CTE_Item_Avg_Profit AS (
    SELECT 
        i.i_item_sk,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_quantity_sold,
    COALESCE(most_returned.return_count, 0) AS most_returned_item_count,
    item_avg.avg_profit,
    CASE 
        WHEN cs.customer_status = 'Active' THEN 'Well Engaged'
        ELSE 'Needs Attention'
    END AS engagement_level,
    ROW_NUMBER() OVER (PARTITION BY cs.customer_status ORDER BY cs.total_quantity_sold DESC) AS rank
FROM CTE_Customer_Sales cs
JOIN CTE_Most_Returned most_returned ON most_returned.sr_item_sk = (
    SELECT sr_item_sk FROM store_returns 
    WHERE sr_returned_date_sk = (
        SELECT MAX(sr_returned_date_sk) FROM store_returns
    ) 
    LIMIT 1
)
JOIN CTE_Item_Avg_Profit item_avg ON item_avg.i_item_sk = most_returned.sr_item_sk
LEFT JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_gender IS NOT NULL AND cd.cd_marital_status = 'S'
ORDER BY cs.total_quantity_sold DESC, item_avg.avg_profit DESC
LIMIT 100
OFFSET 20;
