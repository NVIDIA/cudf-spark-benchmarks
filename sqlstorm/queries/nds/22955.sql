
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
HighVolumeCustomers AS (
    SELECT 
        c.c_customer_sk, 
        cp.total_quantity, 
        cp.order_count,
        CASE 
            WHEN cp.total_quantity > 100 THEN 'High'
            WHEN cp.total_quantity BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low' 
        END AS volume_category
    FROM CustomerPurchases cp
    JOIN customer c ON cp.c_customer_sk = c.c_customer_sk
),
CustomerDemographicInfo AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        hd.hd_income_band_sk,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_estimate
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_quantity,
        hvc.order_count,
        cdi.cd_gender,
        cdi.cd_marital_status,
        cdi.hd_income_band_sk,
        hvc.volume_category,
        COUNT(DISTINCT wp.wp_web_page_id) AS accessed_pages
    FROM HighVolumeCustomers hvc
    LEFT JOIN CustomerDemographicInfo cdi ON hvc.c_customer_sk = cdi.cd_demo_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = hvc.c_customer_sk
    GROUP BY 
        hvc.c_customer_sk, 
        hvc.total_quantity, 
        hvc.order_count, 
        cdi.cd_gender, 
        cdi.cd_marital_status, 
        cdi.hd_income_band_sk, 
        hvc.volume_category
)
SELECT 
    f.c_customer_sk,
    f.total_quantity,
    f.order_count,
    f.cd_gender,
    f.cd_marital_status,
    f.hd_income_band_sk,
    f.volume_category,
    CASE 
        WHEN f.order_count > 5 THEN 'Frequent Buyer'
        WHEN f.order_count BETWEEN 3 AND 5 THEN 'Occasional Buyer'
        ELSE 'Rare Buyer' 
    END AS buyer_status,
    COALESCE(f.accessed_pages, 0) AS accessed_pages
FROM FinalReport f
ORDER BY f.total_quantity DESC, f.order_count DESC, f.c_customer_sk
LIMIT 100;
