
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY c.c_customer_sk) AS country_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
ProductSales AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ps.total_sales,
        ps.order_count,
        cd.country_rank
    FROM
        CustomerDetails cd
    LEFT JOIN
        ProductSales ps ON cd.c_customer_sk = ps.ws_bill_customer_sk
)
SELECT
    cd.full_name,
    cd.ca_city || ', ' || cd.ca_state || ' - ' || cd.ca_country AS full_address,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.order_count, 0) AS order_count,
    cd.country_rank
FROM
    CombinedData cd
WHERE
    cd.total_sales > 1000
ORDER BY
    cd.country_rank,
    cd.total_sales DESC
LIMIT 100;
