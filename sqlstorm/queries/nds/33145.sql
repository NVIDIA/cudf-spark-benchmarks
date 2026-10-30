
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_web_site_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451546
    GROUP BY 
        ws_sold_date_sk, ws_web_site_sk
),
PromotionDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws_net_profit) AS profit_generated,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales WS
    JOIN 
        promotion P ON WS.ws_promo_sk = P.p_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
    HAVING 
        SUM(ws_net_profit) > 5000
),
TopPromotions AS (
    SELECT 
        * 
    FROM 
        PromotionDetails
    ORDER BY 
        profit_generated DESC
    LIMIT 10
)

SELECT 
    C.c_customer_id,
    CA.ca_city,
    COALESCE(SD.total_profit, 0) AS total_profit,
    COALESCE(SD.order_count, 0) AS total_orders,
    TP.p_promo_name,
    TP.profit_generated
FROM 
    customer C
LEFT JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    SalesData SD ON SD.ws_sold_date_sk = 2451545 AND SD.ws_web_site_sk = C.c_current_cdemo_sk
LEFT JOIN 
    TopPromotions TP ON TP.p_promo_sk = C.c_current_hdemo_sk
WHERE 
    CA.ca_state = 'CA' 
    AND (C.c_birth_year IS NULL OR C.c_birth_year < 1990)
ORDER BY 
    total_profit DESC, 
    CA.ca_city ASC;
