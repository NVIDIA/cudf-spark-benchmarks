
WITH SalesData AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        w.w_warehouse_name,
        d.d_year,
        d.d_quarter_seq
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND w.w_state = 'CA'
    GROUP BY 
        ws.ws_web_site_sk, w.w_warehouse_name, d.d_year, d.d_quarter_seq
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS promo_sales
    FROM 
        promotion AS p
    JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    sd.ws_web_site_sk,
    sd.w_warehouse_name,
    sd.total_sales,
    sd.total_orders,
    sd.total_quantity,
    sd.avg_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.max_purchase_estimate,
    cd.orders_count,
    p.promo_sales
FROM 
    SalesData AS sd
LEFT JOIN 
    CustomerData AS cd ON sd.ws_web_site_sk = cd.c_customer_sk
LEFT JOIN 
    Promotions AS p ON sd.ws_web_site_sk = p.p_promo_sk
ORDER BY 
    sd.total_sales DESC, sd.total_orders DESC
LIMIT 100;
