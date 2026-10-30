WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_per_item
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
PromotionalSales AS (
    SELECT 
        CASE 
            WHEN ws.ws_sales_price - (ws.ws_ext_discount_amt / NULLIF(ws.ws_quantity, 0)) > 0 
            THEN (ws.ws_sales_price - (ws.ws_ext_discount_amt / NULLIF(ws.ws_quantity, 0))) 
            ELSE 0
        END AS net_price,
        COUNT(ws.ws_order_number) AS promo_order_count
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY 
        net_price
),
CombinedSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_sales_per_item,
        COALESCE(ps.promo_order_count, 0) AS promo_order_count
    FROM 
        SalesData sd
    LEFT JOIN 
        PromotionalSales ps ON sd.ws_item_sk = ps.net_price
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    cs.ws_item_sk,
    cs.total_quantity,
    cs.total_sales,
    cs.avg_sales_per_item,
    cs.promo_order_count,
    COALESCE(cs.total_sales / NULLIF(cs.total_quantity, 0), 0) AS average_sales_per_unit,
    CASE 
        WHEN cs.avg_sales_per_item > (SELECT AVG(avg_sales_per_item) FROM CombinedSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    CombinedSales cs
JOIN 
    RankedCustomers rc ON cs.ws_item_sk = rc.c_customer_sk
WHERE 
    rc.rnk <= 10
ORDER BY 
    sales_performance DESC, cs.total_sales DESC;