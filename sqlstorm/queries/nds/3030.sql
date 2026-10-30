
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS distinct_ship_dates
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        c.c_customer_id
),
PromotionsUsage AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS usage_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
SalesTrends AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_ext_sales_price) AS yearly_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (
            SELECT AVG(total_sales) FROM CustomerSales
        )
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    pu.usage_count,
    st.yearly_sales,
    st.avg_net_profit
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    PromotionsUsage pu ON hvc.c_customer_id = pu.p_promo_id
CROSS JOIN 
    SalesTrends st
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_sales DESC;
