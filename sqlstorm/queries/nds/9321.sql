
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 
    GROUP BY 
        ws_bill_customer_sk
),
PromotionalImpact AS (
    SELECT 
        c.c_customer_id,
        cs.cs_order_number,
        cs.cs_sales_price,
        p.p_promo_name,
        p.p_discount_active
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE 
        p.p_discount_active = 'Y'
),
FinalReport AS (
    SELECT 
        rs.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales,
        pi.p_promo_name,
        pi.cs_sales_price
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        PromotionalImpact pi ON c.c_customer_id = pi.c_customer_id
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_sales,
    COALESCE(fr.p_promo_name, 'No Promotion') AS promotion_name
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC;
