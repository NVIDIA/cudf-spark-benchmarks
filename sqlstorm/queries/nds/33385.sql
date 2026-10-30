
WITH  price_changes AS (
    SELECT 
        i_item_sk, 
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_rec_start_date DESC) AS rn
    FROM 
        item
    WHERE 
        i_rec_end_date IS NULL
), 
sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_value,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
returns_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_net_loss) AS total_returned_value
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
combined_summary AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales_quantity,
        ss.total_sales_value,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_value, 0) AS total_returned_value,
        (ss.total_sales_value - COALESCE(rs.total_returned_value, 0)) AS net_sales_value,
        (ss.total_sales_quantity - COALESCE(rs.total_returned_quantity, 0)) AS net_sales_quantity
    FROM 
        sales_summary ss
    LEFT JOIN 
        returns_summary rs ON ss.ws_item_sk = rs.wr_item_sk
),
final_summary AS (
    SELECT
        cs.ws_item_sk,
        COALESCE(pc.i_current_price, 0) AS current_price,
        cs.total_sales_quantity,
        cs.net_sales_quantity,
        cs.total_sales_value,
        cs.net_sales_value,
        CASE 
            WHEN cs.net_sales_value > 0 
                THEN ROUND((cs.net_sales_quantity * 100.0 / NULLIF(cs.total_sales_quantity, 0)), 2) 
                ELSE NULL 
        END AS return_rate_percentage
    FROM 
        combined_summary cs
    LEFT JOIN 
        price_changes pc ON cs.ws_item_sk = pc.i_item_sk AND pc.rn = 1
)
SELECT 
    f.ws_item_sk, 
    f.current_price, 
    f.total_sales_quantity,
    f.net_sales_quantity,
    f.total_sales_value,
    f.net_sales_value,
    f.return_rate_percentage
FROM 
    final_summary f
WHERE 
    f.net_sales_value > 5000 
ORDER BY 
    f.net_sales_value DESC;
