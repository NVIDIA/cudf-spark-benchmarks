
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales_data.total_quantity,
        sales_data.total_sales,
        sales_data.total_profit,
        ROW_NUMBER() OVER (PARTITION BY item.i_item_id ORDER BY sales_data.total_profit DESC) AS rank 
    FROM sales_data
    JOIN item ON sales_data.ws_item_sk = item.i_item_sk
),
item_summary AS (
    SELECT 
        i_item_id,
        i_item_desc,
        SUM(total_quantity) AS overall_quantity,
        SUM(total_sales) AS overall_sales,
        SUM(total_profit) AS overall_profit
    FROM top_items
    WHERE rank <= 10
    GROUP BY i_item_id, i_item_desc
)
SELECT 
    item_summary.i_item_id,
    item_summary.i_item_desc,
    item_summary.overall_quantity,
    item_summary.overall_sales,
    item_summary.overall_profit,
    ROUND(item_summary.overall_profit / NULLIF(item_summary.overall_sales, 0), 2) AS profit_margin
FROM item_summary
ORDER BY overall_profit DESC;
