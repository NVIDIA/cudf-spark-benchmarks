
WITH SalesSummary AS (
    SELECT 
        COALESCE(ws_bill_customer_sk, ss_customer_sk) AS customer_sk,
        SUM(ws_ext_sales_price + ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) + COUNT(DISTINCT ss_ticket_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ws_bill_customer_sk, ss_customer_sk) ORDER BY SUM(ws_ext_sales_price + ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws_bill_customer_sk = ss_customer_sk
    GROUP BY 
        COALESCE(ws_bill_customer_sk, ss_customer_sk)
),
HighValueCustomers AS (
    SELECT 
        customer_sk,
        total_sales,
        total_orders,
        CASE 
            WHEN total_sales > 50000 THEN 'High-Value'
            WHEN total_sales BETWEEN 20000 AND 50000 THEN 'Medium-Value'
            ELSE 'Low-Value'
        END AS customer_value
    FROM 
        SalesSummary
    WHERE 
        total_orders > 5
),
IncomeBandCounts AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT h.hd_demo_sk) AS demographic_count
    FROM 
        household_demographics h
    JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    hvc.customer_sk,
    hvc.total_sales,
    hvc.total_orders,
    hvc.customer_value,
    ib.ib_income_band_sk,
    ibc.demographic_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    IncomeBandCounts ibc ON hvc.total_sales BETWEEN 20000 AND 50000
LEFT JOIN 
    income_band ib ON ibc.demographic_count > 50
WHERE 
    (hvc.customer_value = 'High-Value' AND ib.ib_income_band_sk IS NOT NULL)
    OR (hvc.customer_value = 'Medium-Value' AND ib.ib_income_band_sk IS NULL)
ORDER BY 
    hvc.total_sales DESC;
