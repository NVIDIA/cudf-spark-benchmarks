
WITH Address_City AS (
    SELECT
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_length
    FROM
        customer_address
    GROUP BY
        ca_city
),
Customer_Gender AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender
),
Sales_Comparison AS (
    SELECT
        'Web Sales' AS sales_channel,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_quantity) AS avg_quantity
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1 AND 30

    UNION ALL

    SELECT
        'Store Sales' AS sales_channel,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_quantity) AS avg_quantity
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 1 AND 30
),
Income_Band_Averages AS (
    SELECT
        ib_income_band_sk,
        AVG(hd_dep_count) AS avg_dependency_count,
        AVG(hd_vehicle_count) AS avg_vehicle_count
    FROM
        household_demographics
    JOIN
        income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY
        ib_income_band_sk
)
SELECT
    ac.ca_city,
    ac.address_count,
    ac.avg_street_length,
    cg.cd_gender,
    cg.customer_count,
    cg.avg_purchase_estimate,
    s.sales_channel,
    s.total_sales,
    s.avg_quantity,
    ib.ib_income_band_sk,
    ib.avg_dependency_count,
    ib.avg_vehicle_count
FROM
    Address_City ac
JOIN
    Customer_Gender cg ON cg.customer_count > 100
JOIN
    Sales_Comparison s ON s.sales_channel = 'Web Sales'
JOIN
    Income_Band_Averages ib ON ib.avg_dependency_count > 2  
WHERE
    ac.ca_city = 'San Francisco'  
ORDER BY
    ac.address_count DESC, s.total_sales DESC;
