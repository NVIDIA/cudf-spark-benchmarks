
WITH CustomerAddresses AS (
    SELECT
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || 
        COALESCE(' ' || ca_suite_number, '') || ', ' || ca_city || ', ' || ca_state || 
        ' ' || ca_zip AS full_address
    FROM
        customer_address
),
CustomerSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_net_paid) DESC) AS sales_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, cd.cd_gender
),
TopCustomers AS (
    SELECT
        cus.c_customer_sk,
        cus.c_first_name,
        cus.c_last_name,
        cus.total_sales,
        cus.total_spent,
        addr.full_address
    FROM
        CustomerSummary cus
    JOIN
        CustomerAddresses addr ON cus.c_customer_sk = addr.ca_address_sk
    WHERE
        cus.sales_rank <= 10
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_spent,
    tc.full_address
FROM
    TopCustomers tc
ORDER BY
    tc.total_spent DESC;
