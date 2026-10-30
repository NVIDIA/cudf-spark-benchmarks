
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
high_value_sales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_sales_price * r.ws_quantity) AS total_revenue,
        AVG(r.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT r.ws_order_number) AS order_count
    FROM 
        ranked_sales r
    WHERE 
        r.price_rank <= 5
    GROUP BY 
        r.ws_item_sk
),
item_info AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        COALESCE(hd.hd_buy_potential, 'N/A') AS buy_potential,
        COALESCE(ad.ca_city, 'Unknown') AS city,
        COALESCE(ad.ca_state, 'Unknown') AS state
    FROM 
        item i
    LEFT JOIN 
        household_demographics hd ON i.i_item_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer c ON i.i_item_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
),
sales_summary AS (
    SELECT 
        ii.i_item_sk,
        ii.i_product_name,
        ii.buy_potential,
        ii.city,
        ii.state,
        COALESCE(hv.total_revenue, 0) AS total_revenue,
        COALESCE(hv.avg_sales_price, 0) AS avg_sales_price,
        COALESCE(hv.order_count, 0) AS order_count
    FROM 
        item_info ii
    LEFT JOIN 
        high_value_sales hv ON ii.i_item_sk = hv.ws_item_sk
)
SELECT 
    ss.i_product_name,
    ss.buy_potential,
    ss.city,
    ss.state,
    ss.total_revenue,
    ss.avg_sales_price,
    ss.order_count
FROM 
    sales_summary ss
WHERE 
    ss.total_revenue > 0
ORDER BY 
    ss.total_revenue DESC
LIMIT 10;
