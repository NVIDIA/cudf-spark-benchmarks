
WITH addressed_customers AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM
        customer c
    JOIN
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
purchases AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS purchase_count
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_id
),
ranked_customers AS (
    SELECT
        ac.c_customer_id,
        ac.full_name,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip,
        ac.ca_country,
        COALESCE(p.total_sales, 0) AS total_sales,
        COALESCE(p.purchase_count, 0) AS purchase_count,
        DENSE_RANK() OVER (ORDER BY COALESCE(p.total_sales, 0) DESC) AS sales_rank
    FROM
        addressed_customers ac
    LEFT JOIN
        purchases p ON ac.c_customer_id = p.c_customer_id
)
SELECT
    rc.full_name,
    rc.ca_city,
    rc.ca_state,
    rc.ca_zip,
    rc.total_sales,
    rc.purchase_count,
    rc.sales_rank
FROM
    ranked_customers rc
WHERE
    rc.sales_rank <= 10
ORDER BY
    rc.sales_rank;
