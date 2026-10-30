
WITH  sales_summary AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = DATE('2002-10-01') - INTERVAL '30 days')
    GROUP BY 
        cs_item_sk, cs_order_number
    UNION ALL
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = DATE('2002-10-01') - INTERVAL '30 days')
    GROUP BY 
        ws_item_sk, ws_order_number
),
sales_data AS (
    SELECT 
        s.cs_item_sk AS item_sk,
        COALESCE(SUM(s.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(s.total_sales), 0) AS total_sales
    FROM 
        sales_summary s
    GROUP BY 
        s.cs_item_sk
),
ranked_sales AS (
    SELECT 
        sd.item_sk,
        sd.total_quantity,
        sd.total_sales,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    a.ca_city,
    a.ca_state,
    rs.total_quantity,
    rs.total_sales,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_status
FROM 
    ranked_sales rs
JOIN 
    item i ON rs.item_sk = i.i_item_sk
LEFT JOIN 
    customer_address a ON i.i_item_sk = a.ca_address_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND (rs.total_quantity > 0 OR rs.total_sales > 0)
ORDER BY 
    rs.sales_rank, rs.total_sales DESC;
