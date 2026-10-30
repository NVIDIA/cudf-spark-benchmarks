
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
        AND cd.cd_gender IN ('M', 'F')
), ReturningCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_customer_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_tax) AS total_return_tax
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        store_returns sr ON ci.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_customer_id
), PromotionalStats AS (
    SELECT 
        CD.c_customer_sk,
        SUM(CASE 
            WHEN p.p_discount_active = 'Y' THEN ws.ws_net_paid_inc_tax 
            ELSE 0 
            END) AS promotional_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_with_promo
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        CustomerInfo CD ON ws.ws_bill_customer_sk = CD.c_customer_sk
    GROUP BY 
        CD.c_customer_sk
), TotalSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.c_customer_id,
    coalesce(rc.total_returns, 0) AS total_returns,
    coalesce(rc.total_return_amount, 0.00) AS total_return_amount,
    coalesce(ps.promotional_sales, 0.00) AS promotional_sales,
    ts.total_sales,
    CASE 
        WHEN ts.total_sales = 0 THEN 'No Sales'
        ELSE ROUND((coalesce(rc.total_return_amount, 0.00) / ts.total_sales) * 100, 2) || '%' 
    END AS return_rate,
    CASE 
        WHEN ps.orders_with_promo > 0 THEN 'Promotional Customer'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    CustomerInfo ci
LEFT JOIN 
    ReturningCustomers rc ON ci.c_customer_sk = rc.c_customer_sk
LEFT JOIN 
    PromotionalStats ps ON ci.c_customer_sk = ps.c_customer_sk
LEFT JOIN 
    TotalSales ts ON ci.c_customer_sk = ts.c_customer_sk
WHERE 
    ci.cd_gender = 'F' AND (
        rc.total_returns IS NOT NULL 
        OR ps.promotional_sales > 0
    )
ORDER BY 
    return_rate DESC, ci.c_customer_id;
