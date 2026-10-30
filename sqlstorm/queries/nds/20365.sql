
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2021-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2021-12-31')
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_item_sk
),
returns_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr_item_sk
),
sales_returns AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_revenue,
        COALESCE(rs.total_returns, 0) AS total_returns,
        CASE 
            WHEN ss.total_quantity > 0 
            THEN (COALESCE(rs.total_returns, 0) * 1.0 / ss.total_quantity) 
            ELSE NULL 
        END AS return_ratio
    FROM 
        sales_summary ss
    LEFT JOIN 
        returns_summary rs ON ss.ws_item_sk = rs.wr_item_sk
),
final_summary AS (
    SELECT 
        sr.ws_item_sk,
        sr.total_quantity,
        sr.total_revenue,
        sr.total_returns,
        sr.return_ratio,
        CASE 
            WHEN sr.total_revenue > 10000 THEN 'High'
            WHEN sr.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category
    FROM 
        sales_returns sr
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity,
    fs.total_revenue,
    fs.total_returns,
    fs.return_ratio,
    fs.revenue_category,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    a.ca_city,
    a.ca_state
FROM 
    final_summary fs
JOIN 
    web_sales ws ON fs.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE 
    fs.return_ratio IS NOT NULL
    AND fs.return_ratio > (SELECT AVG(return_ratio) FROM sales_returns)
ORDER BY 
    fs.total_revenue DESC
LIMIT 10;

