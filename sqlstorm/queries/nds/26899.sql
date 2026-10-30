
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address 
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_city, ca_state, ca_zip
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws_sales_price > 100 THEN 'High Value'
            WHEN ws_sales_price BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        sales_category
),
CombinedData AS (
    SELECT 
        AD.full_address,
        D.cd_gender,
        D.cd_marital_status,
        D.avg_purchase_estimate,
        S.sales_category,
        S.total_net_profit
    FROM 
        AddressDetails AD
    CROSS JOIN 
        Demographics D
    JOIN 
        SalesData S ON D.avg_purchase_estimate >= 50
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    avg_purchase_estimate,
    sales_category,
    SUM(total_net_profit) AS total_net_profit
FROM 
    CombinedData
GROUP BY 
    full_address, cd_gender, cd_marital_status, avg_purchase_estimate, sales_category
ORDER BY 
    total_net_profit DESC
LIMIT 10;
