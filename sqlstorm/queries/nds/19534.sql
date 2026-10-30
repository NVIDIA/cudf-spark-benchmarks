
SELECT
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    SUM(ss.ss_sales_price) AS total_sales
FROM
    customer AS c
JOIN
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY
    c.c_customer_id, ca.ca_city, cd.cd_gender
ORDER BY
    total_sales DESC
LIMIT 10;
