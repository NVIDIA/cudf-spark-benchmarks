WITH String_Benchmark AS (
    SELECT
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        CASE
            WHEN LENGTH(c.c_email_address) > 40 THEN 'Long'
            ELSE 'Short'
        END AS email_length_category,
        REPLACE(c.c_email_address, '.', '') AS email_without_dots,
        UPPER(c.c_first_name) AS upper_first_name,
        LOWER(c.c_last_name) AS lower_last_name,
        LEFT(c.c_first_name, 3) AS first_name_prefix,
        SUBSTRING(c.c_last_name, 1, 5) AS last_name_prefix,
        
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        c.c_first_name, c.c_last_name, c.c_email_address
)
SELECT
    full_name,
    email_length,
    email_length_category,
    email_without_dots,
    upper_first_name,
    lower_last_name,
    first_name_prefix,
    last_name_prefix,
    demo_count,
    address_count
FROM
    String_Benchmark
WHERE
    email_length_category = 'Long'
ORDER BY
    demo_count DESC, address_count DESC
LIMIT 100;