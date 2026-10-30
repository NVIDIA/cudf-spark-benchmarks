
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS item_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT ws_item_sk
    FROM ranked_sales
    WHERE item_rank <= 10
),
sales_with_promotions AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        p.p_discount_active,
        ws.ws_net_paid_inc_tax,
        p.p_promo_id
    FROM web_sales ws
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_item_sk IN (SELECT * FROM top_items)
),
sales_breakdown AS (
    SELECT 
        swp.ws_item_sk,
        COUNT(*) AS total_orders,
        AVG(swp.ws_sales_price) AS avg_price,
        SUM(swp.ws_net_paid_inc_tax) AS total_revenue,
        CASE 
            WHEN AVG(swp.ws_sales_price) IS NULL THEN 'No Sales'
            ELSE
                CASE 
                    WHEN AVG(swp.ws_sales_price) > 50 THEN 'High Value'
                    ELSE 'Low Value'
                END
        END AS sale_category
    FROM sales_with_promotions swp
    GROUP BY swp.ws_item_sk
)

SELECT 
    it.i_item_id,
    it.i_item_desc,
    sb.total_orders,
    sb.avg_price,
    sb.total_revenue,
    sb.sale_category,
    CASE
        WHEN COUNT(DISTINCT ws_bill_customer_sk) > 10 THEN 'Diverse Customer Base'
        ELSE 'Niche Market'
    END AS market_reach
FROM sales_breakdown sb
JOIN item it ON sb.ws_item_sk = it.i_item_sk
LEFT JOIN web_sales ws ON it.i_item_sk = ws.ws_item_sk
GROUP BY it.i_item_id, it.i_item_desc, sb.total_orders, sb.avg_price, sb.total_revenue, sb.sale_category
HAVING SUM(CASE WHEN ws_bill_customer_sk IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY sb.total_revenue DESC, it.i_item_desc
LIMIT 20;
