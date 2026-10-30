
WITH  customer_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_demo_sk, -1) AS demo_sk,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(cd.cd_gender, 'U') ORDER BY c.c_last_name, c.c_first_name) AS rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_web_page_sk) AS unique_pages
    FROM web_sales
    GROUP BY ws_ship_date_sk
),
inventory_data AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
),
date_filter AS (
    SELECT 
        d.d_date_sk,
        d.d_date
    FROM date_dim d
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    df.d_date,
    cs.rank,
    cs.c_first_name,
    cs.c_last_name,
    ss.total_quantity,
    ss.total_profit,
    CASE 
        WHEN ss.total_profit > 0 THEN 'Profitable'
        ELSE 'Non-Profitable'
    END AS profit_status,
    COALESCE(id.total_inventory, 0) AS available_inventory,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returned_date_sk = df.d_date_sk) AS returns_count
FROM date_filter df
LEFT JOIN customer_rank cs ON cs.demo_sk = (SELECT hd.hd_demo_sk FROM household_demographics hd WHERE hd.hd_dep_count > 2 LIMIT 1)
LEFT JOIN sales_summary ss ON ss.ws_ship_date_sk = df.d_date_sk
LEFT JOIN inventory_data id ON id.inv_date_sk = df.d_date_sk
WHERE (ss.total_quantity > 10 OR id.total_inventory < 100)
ORDER BY df.d_date, cs.rank;
