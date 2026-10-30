
WITH sales_summary AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        cs.cs_item_sk
),
top_items AS (
    SELECT
        ss.cs_item_sk,
        ss.total_quantity,
        ss.total_net_paid,
        ss.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS row_num
    FROM
        sales_summary ss
    WHERE
        ss.profit_rank <= 5
),
item_details AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ti.total_quantity,
        ti.total_net_paid,
        ti.total_net_profit
    FROM
        top_items ti
    JOIN
        item i ON ti.cs_item_sk = i.i_item_sk
)
SELECT
    id.i_item_id,
    id.i_item_desc,
    CASE
        WHEN id.total_quantity > 100 THEN 'High Demand'
        WHEN id.total_quantity BETWEEN 50 AND 100 THEN 'Moderate Demand'
        ELSE 'Low Demand'
    END AS demand_category,
    CAST(id.total_net_paid AS DECIMAL(10, 2)) AS formatted_net_paid,
    CAST(id.total_net_profit AS DECIMAL(10, 2)) AS formatted_net_profit
FROM
    item_details id
LEFT JOIN
    promotion p ON id.total_net_profit > p.p_response_target
WHERE
    p.p_promo_id IS NULL OR p.p_start_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
ORDER BY
    id.total_net_profit DESC;
