
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
item_inventory AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
latest_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_paid,
        ii.total_quantity_on_hand,
        DENSE_RANK() OVER (ORDER BY ss.total_net_paid DESC) AS rank
    FROM sales_summary ss
    LEFT JOIN item_inventory ii ON ss.ws_item_sk = ii.inv_item_sk
    WHERE ss.rn = 1
),
filtered_sales AS (
    SELECT 
        ls.ws_item_sk,
        ls.total_quantity,
        ls.total_net_paid,
        ls.total_quantity_on_hand
    FROM latest_sales ls
    WHERE ls.total_net_paid > (SELECT AVG(total_net_paid) FROM latest_sales) 
          AND ls.total_quantity > (SELECT COALESCE(MAX(total_quantity), 0) FROM latest_sales WHERE rank <= 10)
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fs.total_quantity,
    fs.total_net_paid,
    COALESCE(fs.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    i.i_current_price,
    CASE 
        WHEN fs.total_net_paid > 1000 THEN 'High Value'
        WHEN fs.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment,
    CONCAT('Item ID: ', i.i_item_id, ' has generated total sales of ', CAST(fs.total_net_paid AS VARCHAR(50))) AS sales_message
FROM filtered_sales fs
JOIN item i ON fs.ws_item_sk = i.i_item_sk
ORDER BY fs.total_net_paid DESC
LIMIT 50 OFFSET 0;
