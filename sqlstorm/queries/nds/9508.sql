
WITH sales_summary AS (
    SELECT 
        C.c_customer_id,
        COUNT(DISTINCT WS.ws_order_number) AS total_orders,
        SUM(WS.ws_sales_price * WS.ws_quantity) AS total_revenue,
        SUM(WS.ws_sales_price * WS.ws_quantity * (1 - WS.ws_ext_discount_amt / NULLIF(WS.ws_list_price * WS.ws_quantity, 0))) AS net_revenue,
        AVG(WS.ws_sales_price) AS avg_order_value
    FROM 
        web_sales WS
    JOIN 
        customer C ON WS.ws_bill_customer_sk = C.c_customer_sk
    JOIN 
        date_dim DD ON WS.ws_sold_date_sk = DD.d_date_sk
    WHERE 
        DD.d_year = 2023 AND DD.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        C.c_customer_id
),
promotions_data AS (
    SELECT 
        PS.p_promo_id,
        SUM(WS.ws_sales_price * WS.ws_quantity) AS promo_revenue
    FROM 
        promotion PS
    JOIN 
        web_sales WS ON PS.p_promo_sk = WS.ws_promo_sk
    GROUP BY 
        PS.p_promo_id
),
high_value_customers AS (
    SELECT 
        C.c_customer_id,
        S.total_orders,
        S.total_revenue,
        S.net_revenue,
        S.avg_order_value
    FROM 
        sales_summary S
    JOIN 
        customer C ON S.c_customer_id = C.c_customer_id
    WHERE 
        S.total_revenue > (SELECT AVG(total_revenue) FROM sales_summary) AND S.total_orders > 2
)
SELECT 
    H.c_customer_id,
    H.total_orders,
    H.total_revenue,
    H.net_revenue,
    H.avg_order_value,
    COALESCE(PD.promo_revenue, 0) AS total_promo_revenue
FROM 
    high_value_customers H
LEFT JOIN 
    promotions_data PD ON H.c_customer_id = PD.p_promo_id
ORDER BY 
    H.net_revenue DESC
LIMIT 100;
