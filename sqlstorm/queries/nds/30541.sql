
WITH  sale_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_prefs AS (
    SELECT
        c_customer_sk,
        d_year AS purchase_year,
        COUNT(ws_order_number) AS order_count,
        MIN(ws_net_profit) AS min_profit,
        MAX(ws_net_profit) AS max_profit
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        c.c_birth_year IS NOT NULL AND
        (c.c_birth_month = 12 OR c.c_birth_day IS NULL)
    GROUP BY
        c_customer_sk, d_year
),
sales_ranked AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.purchase_year,
        cp.order_count,
        cp.min_profit,
        cp.max_profit,
        ROW_NUMBER() OVER (PARTITION BY cp.purchase_year ORDER BY cp.order_count DESC) AS customer_ranking
    FROM
        customer_prefs cp
    JOIN customer c ON cp.c_customer_sk = c.c_customer_sk
),
final_summary AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales_price,
        sr.c_first_name,
        sr.c_last_name,
        sr.customer_ranking
    FROM
        sale_summary ss
    LEFT JOIN sales_ranked sr ON sr.purchase_year = 2023 AND sr.customer_ranking <= 10
)
SELECT
    item.i_item_id,
    item.i_item_desc,
    COALESCE(fs.total_quantity, 0) AS total_quantity_sold,
    COALESCE(fs.total_sales_price, 0) AS total_sales,
    CONCAT(COALESCE(fs.c_first_name, 'N/A'), ' ', COALESCE(fs.c_last_name, 'N/A')) AS top_customer
FROM
    item
LEFT JOIN final_summary fs ON item.i_item_sk = fs.ws_item_sk
WHERE
    (item.i_current_price > 20 OR item.i_brand LIKE '%Electronics%')
    AND item.i_rec_end_date IS NULL
ORDER BY
    total_quantity_sold DESC,
    total_sales DESC;
