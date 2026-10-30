
SELECT
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ss_sales_price) AS total_sales
FROM
    customer c
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE
    cd.cd_gender = 'F' AND
    cd.cd_marital_status = 'M'
GROUP BY
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status
HAVING
    SUM(ss.ss_sales_price) > 1000
ORDER BY
    total_sales DESC
LIMIT 100;
