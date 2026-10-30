WITH SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20200 AND 20230 
    GROUP BY
        ws_bill_customer_sk
),
CustomerData AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
HighValueCustomers AS (
    SELECT
        sd.ws_bill_customer_sk,
        sd.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_city,
        cd.ca_state
    FROM
        SalesData sd
    JOIN
        CustomerData cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
    WHERE
        sd.rank <= 10 
)
SELECT
    hvc.ws_bill_customer_sk,
    hvc.total_sales,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.ca_city,
    hvc.ca_state,
    CASE
        WHEN hvc.cd_marital_status = 'M' THEN 'Married'
        WHEN hvc.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status_label,
    COALESCE((SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = hvc.ws_bill_customer_sk), 0) AS store_purchase_count,
    COALESCE((SELECT SUM(ss_ext_sales_price) FROM store_sales ss WHERE ss.ss_customer_sk = hvc.ws_bill_customer_sk), 0) AS total_store_sales
FROM
    HighValueCustomers hvc
ORDER BY
    hvc.total_sales DESC;