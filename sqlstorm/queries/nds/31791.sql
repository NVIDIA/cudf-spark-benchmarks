
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(d.d_date_sk) 
        FROM date_dim d 
        WHERE d.d_year = 2023
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
    HAVING SUM(ws.ws_ext_sales_price) > 1000

    UNION ALL

    SELECT 
        hd.hd_demo_sk,
        NULL AS c_first_name,
        NULL AS c_last_name,
        NULL AS c_email_address,
        AVG(hd.hd_dep_count + hd.hd_vehicle_count) AS total_sales
    FROM household_demographics hd
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IS NOT NULL
    GROUP BY hd.hd_demo_sk
    HAVING AVG(hd.hd_dep_count + hd.hd_vehicle_count) > 5
)

SELECT 
    sh.c_customer_sk,
    CONCAT(COALESCE(sh.c_first_name, ''), ' ', COALESCE(sh.c_last_name, '')) AS full_name,
    sh.c_email_address,
    sh.total_sales,
    CASE 
        WHEN sh.total_sales IS NULL THEN 'No Sales'
        WHEN sh.total_sales > 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value
FROM SalesHierarchy sh
LEFT JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
ORDER BY sh.total_sales DESC
LIMIT 10;
