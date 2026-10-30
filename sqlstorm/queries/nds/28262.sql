
WITH AddressFrequency AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        CAST(d.d_date AS DATE) AS sale_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        CAST(d.d_date AS DATE)
)
SELECT 
    af.ca_state,
    af.address_count,
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate,
    d.total_dependents,
    sd.sale_date,
    sd.total_sales,
    sd.total_orders
FROM 
    AddressFrequency af
FULL OUTER JOIN 
    Demographics d ON af.ca_state IS NOT NULL
FULL OUTER JOIN 
    SalesData sd ON sd.sale_date IS NOT NULL
ORDER BY 
    af.address_count DESC, 
    d.customer_count DESC, 
    sd.total_sales DESC;
