
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') 
                               AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY cs_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_profit,
        sd.order_count,
        CASE 
            WHEN sd.total_profit > 10000 THEN 'High'
            WHEN sd.total_profit BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM SalesData sd
    JOIN item i ON sd.cs_item_sk = i.i_item_sk
),
TopItems AS (
    SELECT 
        id.i_item_id,
        id.i_item_desc,
        id.total_profit,
        id.order_count,
        id.profit_category,
        ROW_NUMBER() OVER (PARTITION BY id.profit_category ORDER BY id.total_profit DESC) AS rank
    FROM ItemDetails id
)
SELECT 
    ti.profit_category,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_profit,
    ti.order_count
FROM TopItems ti
WHERE ti.rank <= 5
ORDER BY ti.profit_category, ti.total_profit DESC;
