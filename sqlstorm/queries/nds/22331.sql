
WITH  sales_cte AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_sold, COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sales_price > 10
    GROUP BY ws_item_sk
), inventory_check AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
), promotion_stats AS (
    SELECT p_item_sk, AVG(p_cost) AS avg_cost, COUNT(DISTINCT p_promo_id) AS promo_count,
           MAX(p_response_target) AS max_response
    FROM promotion
    WHERE p_discount_active = 'Y'
    GROUP BY p_item_sk
), combined_stats AS (
    SELECT s.ws_item_sk,
           COALESCE(s.total_sold, 0) AS total_sold,
           COALESCE(i.total_on_hand, 0) AS total_on_hand,
           COALESCE(p.avg_cost, 0) AS avg_cost,
           COALESCE(p.promo_count, 0) AS promo_count,
           COALESCE(p.max_response, 0) AS max_response
    FROM sales_cte s
    FULL OUTER JOIN inventory_check i ON s.ws_item_sk = i.inv_item_sk
    FULL OUTER JOIN promotion_stats p ON s.ws_item_sk = p.p_item_sk
), ranked_items AS (
    SELECT ws_item_sk, total_sold, total_on_hand, avg_cost, promo_count, max_response,
           ROW_NUMBER() OVER (PARTITION BY CASE WHEN total_on_hand = 0 THEN 'Out of Stock' ELSE 'In Stock' END
                            ORDER BY total_sold DESC, avg_cost ASC) AS rank
    FROM combined_stats
)
SELECT item_analytics.ws_item_sk,
       item_analytics.total_sold,
       item_analytics.total_on_hand,
       item_analytics.avg_cost,
       item_analytics.promo_count,
       item_analytics.max_response,
       CASE 
           WHEN item_analytics.rank <= 10 THEN 'High Performer'
           WHEN item_analytics.rank BETWEEN 11 AND 20 THEN 'Medium Performer'
           ELSE 'Low Performer'
       END AS performance_category
FROM ranked_items item_analytics
WHERE item_analytics.rank <= 20
ORDER BY item_analytics.total_sold DESC, item_analytics.avg_cost ASC;

