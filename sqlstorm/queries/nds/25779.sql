WITH AddressComponents AS (
    SELECT
        ca_address_sk,
        CONCAT(
            TRIM(ca_street_number), ' ', 
            TRIM(ca_street_name), ' ', 
            TRIM(ca_street_type), ', ', 
            TRIM(ca_city), ', ', 
            TRIM(ca_state), ' ', 
            TRIM(ca_zip), ' ', 
            TRIM(ca_country)
        ) AS full_address
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        a.full_address,
        c.c_email_address
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        AddressComponents a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
MonthlySales AS (
    SELECT
        EXTRACT(YEAR FROM d.d_date) AS year,
        EXTRACT(MONTH FROM d.d_date) AS month,
        SUM(cs_ext_sales_price) AS monthly_sales
    FROM
        date_dim d
    JOIN
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY
        year, month
)
SELECT 
    c.full_name,
    c.full_address,
    c.c_email_address,
    COALESCE(sd.total_sales, 0) AS total_web_sales,
    COALESCE(ms.monthly_sales, 0) AS current_month_sales,
    cast('2002-10-01' as date) AS query_date
FROM 
    CustomerInfo c
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    MonthlySales ms ON ms.year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) 
                     AND ms.month = EXTRACT(MONTH FROM cast('2002-10-01' as date))
WHERE 
    c.cd_gender = 'F' 
    AND c.cd_marital_status = 'M'
ORDER BY 
    total_web_sales DESC;