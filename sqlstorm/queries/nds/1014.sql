WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2500 AND 3000
        AND ws.ws_net_paid > 20
),
TopSales AS (
    SELECT 
        sd.c_customer_id,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_spent,
        COUNT(*) AS purchase_count,
        MAX(sd.ws_net_paid) AS max_purchase,
        AVG(sd.ws_sales_price) AS avg_price
    FROM 
        SalesData sd
    WHERE 
        sd.rn <= 5 
    GROUP BY 
        sd.c_customer_id
),
PromotionStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ts.c_customer_id,
    ts.total_spent,
    ts.purchase_count,
    ts.max_purchase,
    ts.avg_price,
    ps.order_count,
    ps.total_revenue
FROM 
    TopSales ts
FULL OUTER JOIN 
    PromotionStats ps ON ts.purchase_count = COALESCE(ps.order_count, 0) 
WHERE 
    ts.total_spent > 100 OR ps.total_revenue > 1000
ORDER BY 
    ts.total_spent DESC, ps.total_revenue DESC;