
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_discount_amt,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL AND
        ws_sales_price > 0
),
sales_summary AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT sd.ws_order_number) AS order_count
    FROM 
        sales_data sd
    WHERE 
        sd.rn <= 5  
    GROUP BY 
        sd.ws_item_sk
),
address_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        COALESCE(c.c_current_addr_sk, -1) AS addr_sk_fallback
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        ai.c_first_name,
        ai.c_last_name,
        ai.ca_city,
        ai.ca_state
    FROM 
        sales_summary ss
    LEFT JOIN 
        address_info ai ON ss.ws_item_sk = ai.c_customer_sk 
    WHERE 
        ss.total_sales > 1000  
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ts.total_discount,
    COALESCE(ts.c_first_name, 'Unknown') AS first_name,
    COALESCE(ts.c_last_name, 'Unknown') AS last_name,
    ts.ca_city,
    CASE 
        WHEN ts.ca_state IS NULL THEN 'Unknown State' 
        ELSE ts.ca_state 
    END AS state
FROM 
    top_sales ts 
RIGHT JOIN 
    warehouse w ON w.w_warehouse_sk = ts.ws_item_sk  
ORDER BY 
    ts.total_sales DESC,
    w.w_warehouse_name;
