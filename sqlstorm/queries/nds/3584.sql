WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 1999 AND d_month_seq BETWEEN 1 AND 12
        )
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_net_profit
    FROM 
        item
    JOIN SalesData sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.profit_rank <= 10
)
SELECT 
    COALESCE(ti.i_item_id, 'Not Available') AS item_id,
    ti.i_item_desc AS item_description,
    CASE 
        WHEN ti.total_quantity > 100 THEN 'High Sales'
        WHEN ti.total_quantity BETWEEN 50 AND 100 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    ti.total_net_profit,
    'Processed on: ' || cast('2002-10-01' as date) AS processing_date_info
FROM 
    TopItems AS ti
FULL OUTER JOIN 
    store AS s ON ti.total_quantity = s.s_number_employees
WHERE 
    s.s_state = 'CA'
    OR ti.total_net_profit IS NOT NULL
ORDER BY 
    ti.total_net_profit DESC NULLS LAST;