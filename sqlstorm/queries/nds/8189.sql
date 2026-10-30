
WITH sales_summary AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sold,
        SUM(cs.cs_net_paid) AS total_revenue,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        MAX(cs.cs_sales_price) AS highest_price,
        MIN(cs.cs_sales_price) AS lowest_price
    FROM
        catalog_sales cs
    JOIN
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > 0
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_item_sk
),
customer_address_summary AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(ss.total_revenue) AS total_spent,
        AVG(ss.total_sold) AS avg_items_sold
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        sales_summary ss ON c.c_customer_sk = ss.cs_item_sk
    GROUP BY
        c.c_customer_sk,
        ca.ca_state
)
SELECT
    cas.ca_state,
    SUM(cas.unique_customers) AS total_customers,
    SUM(cas.total_spent) AS state_revenue,
    AVG(cas.avg_items_sold) AS state_avg_sold
FROM
    customer_address_summary cas
GROUP BY
    cas.ca_state
ORDER BY
    state_revenue DESC
LIMIT 10;
