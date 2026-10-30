
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
DemographicSummary AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
SalesByRegion AS (
    SELECT
        ca_state,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        customer_address ON ws_bill_addr_sk = ca_address_sk
    GROUP BY 
        ca_state
),
CombinedResults AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.customer_count,
        d.avg_purchase_estimate,
        r.total_orders,
        r.total_sales
    FROM 
        AddressParts a
    LEFT JOIN 
        DemographicSummary d ON d.customer_count > 0
    LEFT JOIN 
        SalesByRegion r ON a.ca_state = r.ca_state
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    customer_count,
    avg_purchase_estimate,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(total_sales, 0.00) AS total_sales,
    CONCAT('Total Orders: ', COALESCE(total_orders, 0), ', Total Sales: $', CAST(COALESCE(total_sales, 0.00) AS DECIMAL(10, 2))) AS sales_summary
FROM 
    CombinedResults
WHERE 
    customer_count > 10
ORDER BY 
    total_sales DESC, ca_state, ca_city;
