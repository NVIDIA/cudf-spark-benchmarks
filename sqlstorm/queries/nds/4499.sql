WITH replicated_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_web_quantity,
        SUM(ws_net_paid) AS total_web_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451935 AND 2451970  
    GROUP BY 
        ws_item_sk
),
catalog_returns_data AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
sales_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(rs.total_web_quantity, 0) AS web_quantity,
        COALESCE(rs.total_web_net_paid, 0) AS web_net_paid,
        COALESCE(crs.total_return_quantity, 0) AS return_quantity,
        COALESCE(crs.total_return_amount, 0) AS return_amount,
        CASE 
            WHEN COALESCE(rs.total_web_quantity, 0) > 0 
            THEN (COALESCE(crs.total_return_quantity, 0) * 1.0 / rs.total_web_quantity) * 100 
            ELSE NULL 
        END AS return_percentage
    FROM 
        item i
    LEFT JOIN 
        replicated_sales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        catalog_returns_data crs ON i.i_item_sk = crs.cr_item_sk
)
SELECT 
    s.i_item_id,
    s.i_item_desc,
    s.web_quantity,
    s.web_net_paid,
    s.return_quantity,
    s.return_amount,
    s.return_percentage,
    ROW_NUMBER() OVER (ORDER BY s.return_percentage DESC) AS return_rank,
    CASE 
        WHEN s.return_percentage IS NULL THEN 'No sales'
        WHEN s.return_percentage > 20 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_category
FROM 
    sales_summary s
WHERE 
    s.return_percentage IS NOT NULL
ORDER BY 
    s.return_percentage DESC;