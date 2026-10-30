
WITH Rankd_Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Filtered_Customer AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        CASE 
            WHEN d.d_current_month = 'Y' THEN 'Recent'
            WHEN d.d_current_year = 'Y' THEN 'Current'
            ELSE 'Older'
        END AS customer_age_category
    FROM 
        customer c
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
Top_Sold_Items AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        RANK() OVER (ORDER BY rs.total_quantity DESC) AS rank_order
    FROM 
        Rankd_Sales rs
    WHERE 
        rs.total_quantity > 100 
)
SELECT 
    c.c_customer_id,
    c.customer_age_category,
    s.ss_item_sk,
    i.i_item_desc,
    COALESCE(s.ss_net_profit, 0) AS net_profit,
    COALESCE(s.ss_quantity, 0) AS quantity_sold,
    CASE 
        WHEN s.ss_coupon_amt > 0 THEN 'Discounted'
        ELSE 'Regular Price'
    END AS sale_type
FROM 
    Top_Sold_Items ti
LEFT JOIN 
    store_sales s ON ti.ws_item_sk = s.ss_item_sk
JOIN 
    Filtered_Customer c ON s.ss_customer_sk = c.c_customer_sk
JOIN 
    item i ON s.ss_item_sk = i.i_item_sk
WHERE 
    (s.ss_net_profit IS NULL OR s.ss_net_profit > 0)
    AND (i.i_color LIKE 'R%' OR i.i_brand = 'BrandX')
ORDER BY 
    c.customer_age_category, ti.total_quantity DESC, s.ss_net_profit DESC;
