
WITH filtered_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ca.ca_city LIKE '%Springfield%'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
),
sales_summary AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        AVG(cs_sales_price) AS avg_sales_price
    FROM
        catalog_sales
    GROUP BY
        cs_bill_customer_sk
),
final_summary AS (
    SELECT
        fc.c_customer_id,
        fc.c_first_name,
        fc.c_last_name,
        fc.ca_city,
        fc.ca_state,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.avg_sales_price, 0) AS avg_sales_price
    FROM
        filtered_customers fc
    LEFT JOIN
        sales_summary ss ON fc.c_customer_id = CAST(ss.cs_bill_customer_sk AS CHAR(16))
)
SELECT
    *,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    '(' || ca_city || ', ' || ca_state || ')' AS location,
    CASE 
        WHEN total_quantity > 100 THEN 'High Buyer'
        WHEN total_quantity BETWEEN 50 AND 100 THEN 'Medium Buyer'
        ELSE 'Low Buyer' 
    END AS buyer_category
FROM
    final_summary
ORDER BY
    total_orders DESC,
    total_quantity DESC;
