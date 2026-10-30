
WITH CustomerPurchases AS (
    SELECT
        c.c_customer_sk,
        CD.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY
        c.c_customer_sk, CD.cd_gender
),
HighValueCustomers AS (
    SELECT
        cp.c_customer_sk,
        cp.total_sales,
        cp.order_count,
        CASE
            WHEN cp.total_sales > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM
        CustomerPurchases cp
)
SELECT
    c.c_customer_id,
    hvc.total_sales,
    hvc.order_count,
    hvc.customer_type,
    da.ca_city,
    da.ca_state
FROM
    HighValueCustomers hvc
JOIN
    customer c ON hvc.c_customer_sk = c.c_customer_sk
JOIN
    customer_address da ON da.ca_address_sk = c.c_current_addr_sk
WHERE
    hvc.customer_type = 'High Value'
ORDER BY
    hvc.total_sales DESC
LIMIT 10;
