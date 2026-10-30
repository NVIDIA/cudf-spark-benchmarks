
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023) - 90
        AND (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.total_sales,
        c.order_count,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM
        CustomerSales AS c
)
SELECT
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    COALESCE(d.d_region, 'Unknown') AS region,
    CASE
        WHEN tc.order_count > 10 THEN 'High Engagement'
        WHEN tc.order_count BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM
    TopCustomers AS tc
LEFT JOIN (
    SELECT
        ca.ca_address_id,
        CASE 
            WHEN ca.ca_state IN ('CA', 'NY') THEN 'West Coast'
            WHEN ca.ca_state IN ('TX', 'FL') THEN 'South'
            ELSE 'Other'
        END AS d_region
    FROM
        customer_address AS ca
) AS d ON tc.customer_id = d.ca_address_id
WHERE
    tc.sales_rank <= 100
ORDER BY
    tc.total_sales DESC
LIMIT 50;
