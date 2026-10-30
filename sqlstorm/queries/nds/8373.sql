
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk, total_sales, order_count, cd_gender, cd_marital_status, cd_education_status
    FROM 
        CustomerSales
    WHERE 
        total_sales > 1000
),
PromotionalData AS (
    SELECT 
        hvc.c_customer_sk,
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_usage_count
    FROM 
        HighValueCustomers hvc
    JOIN 
        web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        hvc.c_customer_sk, p.p_promo_id, p.p_promo_name
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_sales,
    hvc.order_count,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    pd.p_promo_id,
    pd.p_promo_name,
    pd.promo_usage_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    PromotionalData pd ON hvc.c_customer_sk = pd.c_customer_sk
ORDER BY 
    hvc.total_sales DESC;
