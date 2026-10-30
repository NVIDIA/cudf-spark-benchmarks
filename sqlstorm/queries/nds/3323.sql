
WITH customer_stats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS total_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating = 'Unknown' THEN 1 ELSE 0 END) AS unknown_credit_count
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cs.cd_demo_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        ss.total_sales,
        ss.total_tax
    FROM 
        customer_stats cs
    LEFT JOIN 
        sales_data ss ON cs.cd_demo_sk = ss.ws_bill_customer_sk
    WHERE 
        cs.total_purchase_estimate > 1000  
        AND ss.total_sales IS NOT NULL
),
final_report AS (
    SELECT 
        hvc.cd_gender,
        hvc.cd_marital_status,
        COUNT(hvc.cd_demo_sk) AS high_value_customers_count,
        AVG(hvc.total_sales) AS avg_sales,
        SUM(COALESCE(hvc.total_tax, 0)) AS total_tax_collected
    FROM 
        high_value_customers hvc
    GROUP BY 
        hvc.cd_gender, hvc.cd_marital_status
)
SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.high_value_customers_count,
    fr.avg_sales,
    fr.total_tax_collected,
    CASE 
        WHEN fr.total_tax_collected IS NULL THEN 'No Tax'
        WHEN fr.avg_sales IS NULL THEN 'No Sales'
        ELSE 'Valid Data'
    END AS data_status
FROM 
    final_report fr
ORDER BY 
    high_value_customers_count DESC,
    avg_sales DESC;
