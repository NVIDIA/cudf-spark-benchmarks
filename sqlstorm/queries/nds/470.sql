
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid_inc_tax) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate, 
        ca_city,
        sd.total_sales,
        sd.order_count
    FROM 
        SalesData sd 
    JOIN 
        customer c ON sd.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        sd.rn = 1
),
PromotionsData AS (
    SELECT 
        p.p_promo_sk, 
        p.p_promo_name, 
        COUNT(ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, 
        p.p_promo_name
)
SELECT 
    tc.cd_gender,
    tc.cd_marital_status,
    COUNT(tc.cd_demo_sk) AS customer_count,
    AVG(tc.total_sales) AS avg_sales,
    SUM(tc.order_count) AS total_orders,
    promotion.promo_order_count,
    CASE 
        WHEN AVG(tc.total_sales) > 1000 THEN 'High Value'
        WHEN AVG(tc.total_sales) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionsData promotion ON tc.cd_demo_sk = promotion.p_promo_sk
GROUP BY 
    tc.cd_gender,
    tc.cd_marital_status,
    promotion.promo_order_count
ORDER BY 
    customer_count DESC;
