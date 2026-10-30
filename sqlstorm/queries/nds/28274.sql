
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state) AS full_address
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address
    FROM
        customer c
    JOIN
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
FilteredCustomers AS (
    SELECT
        ci.c_customer_sk,
        ci.full_name,
        ci.full_address,
        d.d_date
    FROM
        CustomerInfo ci
    JOIN
        date_dim d ON d.d_date_sk = ci.c_customer_sk % (SELECT COUNT(*) FROM date_dim) + 1
    WHERE
        ci.full_address LIKE '%New%'
        AND ci.full_address LIKE '%York%'
)
SELECT
    fc.full_name,
    fc.full_address,
    d.d_day_name,
    d.d_month_seq,
    COUNT(*) AS occurrences
FROM
    FilteredCustomers fc
JOIN
    date_dim d ON d.d_date_sk = fc.c_customer_sk
GROUP BY
    fc.full_name,
    fc.full_address,
    d.d_day_name,
    d.d_month_seq
ORDER BY
    occurrences DESC;
