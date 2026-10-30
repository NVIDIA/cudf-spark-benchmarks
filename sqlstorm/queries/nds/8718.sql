
WITH RevenueSummary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_sales_price - ws.ws_ext_discount_amt) AS net_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales_by_demo
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), PromotionEffect AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS promotion_sales
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    rs.w_warehouse_id, 
    rs.d_year,
    rs.total_sales,
    rs.total_discount,
    rs.net_revenue,
    cd.total_sales_by_demo,
    pe.order_count,
    pe.promotion_sales
FROM 
    RevenueSummary rs 
LEFT JOIN 
    CustomerDemographics cd ON cd.total_sales_by_demo > 0
LEFT JOIN 
    PromotionEffect pe ON pe.order_count > 0
ORDER BY 
    rs.w_warehouse_id, rs.d_year DESC;
