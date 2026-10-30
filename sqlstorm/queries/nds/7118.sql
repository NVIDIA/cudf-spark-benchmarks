
WITH SalesSummary AS (
    SELECT 
        d.d_year AS SalesYear,
        d.d_moy AS SalesMonth,
        d.d_day_name AS SalesDayName,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS UniqueCustomers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2022
        AND cd.cd_gender = 'F'
    GROUP BY 
        d.d_year, d.d_moy, d.d_day_name
),
PromotionSummary AS (
    SELECT 
        pm.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS TotalPromoSales,
        COUNT(DISTINCT ws.ws_order_number) AS PromoOrderCount
    FROM 
        web_sales ws
    JOIN 
        promotion pm ON ws.ws_promo_sk = pm.p_promo_sk
    GROUP BY 
        pm.p_promo_name
)
SELECT 
    ss.SalesYear,
    ss.SalesMonth,
    ss.SalesDayName,
    ss.TotalSales,
    ss.TotalOrders,
    ss.UniqueCustomers,
    ps.TotalPromoSales,
    ps.PromoOrderCount
FROM 
    SalesSummary ss
LEFT JOIN 
    PromotionSummary ps ON ss.SalesYear = 2022
ORDER BY 
    ss.SalesYear, ss.SalesMonth, ss.SalesDayName;
