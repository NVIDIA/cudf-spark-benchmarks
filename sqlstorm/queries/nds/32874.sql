
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 0
),
Store_Sales_CTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_net_profit) AS store_net_profit
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
Date_Stats AS (
    SELECT 
        d_year,
        COUNT(*) AS order_count,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_orders
    FROM 
        date_dim
    WHERE 
        d_year >= 2000
    GROUP BY 
        d_year
),
Promotions AS (
    SELECT 
        p_item_sk,
        COUNT(*) AS promo_count,
        SUM(p_cost) AS total_promo_cost
    FROM 
        promotion
    GROUP BY 
        p_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(SC.total_quantity, 0) AS total_web_quantity,
    COALESCE(SSC.store_quantity, 0) AS total_store_quantity,
    COALESCE(DS.order_count, 0) AS total_order_count,
    COALESCE(DS.holiday_orders, 0) AS holiday_order_count,
    COALESCE(P.total_promo_cost, 0) AS total_promo_cost,
    COALESCE(SC.total_net_profit, 0) + COALESCE(SSC.store_net_profit, 0) AS total_net_profit_combined
FROM 
    item i
LEFT JOIN 
    Sales_CTE SC ON i.i_item_sk = SC.ws_item_sk
LEFT JOIN 
    Store_Sales_CTE SSC ON i.i_item_sk = SSC.ss_item_sk
LEFT JOIN 
    Date_Stats DS ON DS.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
LEFT JOIN 
    Promotions P ON i.i_item_sk = P.p_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND (COALESCE(SC.total_quantity, 0) > 100 OR COALESCE(SSC.store_quantity, 0) > 100)
ORDER BY 
    total_net_profit_combined DESC
LIMIT 100;
