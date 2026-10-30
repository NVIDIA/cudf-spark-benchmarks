WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451928 
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        hd.hd_income_band_sk
),
HighValueCustomers AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent > 10000 THEN 'High'
            WHEN total_spent BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS customer_value_segment
    FROM 
        CustomerMetrics
),
CustomerShippingModes AS (
    SELECT 
        c.c_customer_sk,
        sm.sm_type AS preferred_shipping_mode,
        COUNT(sm.sm_ship_mode_sk) AS shipment_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        sm.sm_type
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.hd_income_band_sk,
    hvc.total_purchases,
    hvc.total_spent,
    hvc.customer_value_segment,
    csm.preferred_shipping_mode,
    csm.shipment_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerShippingModes csm ON hvc.c_customer_sk = csm.c_customer_sk
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;