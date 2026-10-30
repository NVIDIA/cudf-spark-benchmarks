
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_shipment_dates,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    ss.c_customer_id,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.total_sales,
    ss.order_count,
    ss.unique_shipment_dates,
    ss.avg_net_profit,
    p.promo_order_count,
    p.promo_sales
FROM 
    sales_summary ss
LEFT JOIN 
    promotions p ON ss.total_sales > p.promo_sales
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
