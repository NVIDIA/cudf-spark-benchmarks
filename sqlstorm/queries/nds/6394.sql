
WITH CustomerData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        i.i_item_desc,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN
        item AS i ON ss.ss_item_sk = i.i_item_sk
    WHERE
        cd.cd_gender = 'F'
        AND ca.ca_state IN ('NY', 'CA')
        AND cd.cd_purchase_estimate > 1000
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        i.i_item_desc
    HAVING
        SUM(ss.ss_quantity) > 10
    ORDER BY
        total_sales_amount DESC
),
SalesSummary AS (
    SELECT
        ca.ca_city,
        COUNT(DISTINCT cd.c_customer_sk) AS female_customers,
        SUM(cd.total_sales_quantity) AS total_quantity_sold,
        SUM(cd.total_sales_amount) AS total_sales_value
    FROM
        CustomerData AS cd
    JOIN
        customer_address AS ca ON cd.c_customer_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_city
)
SELECT
    ss.ca_city,
    ss.female_customers,
    ss.total_quantity_sold,
    ss.total_sales_value,
    pd.p_discount_active
FROM
    SalesSummary AS ss
LEFT JOIN
    promotion AS pd ON pd.p_item_sk IN (SELECT i.i_item_sk FROM item AS i WHERE i.i_item_desc LIKE '%discount%')
ORDER BY
    ss.total_sales_value DESC
LIMIT 50;
