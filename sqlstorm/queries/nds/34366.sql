
WITH  sales_cte AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
),
customer_sales AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender
    HAVING
        SUM(ws.ws_ext_sales_price) IS NOT NULL
),
yearly_average_sales AS (
    SELECT
        d.d_year,
        AVG(s.total_sales) AS avg_sales
    FROM
        date_dim d
    JOIN sales_cte s ON d.d_date_sk = s.ws_sold_date_sk
    GROUP BY
        d.d_year
),
top_customers AS (
    SELECT
        cs.c_customer_id,
        cs.total_web_sales,
        cs.web_order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS rnk
    FROM
        customer_sales cs
    WHERE
        cs.total_web_sales > (
            SELECT
                AVG(total_web_sales) FROM customer_sales
        )
)
SELECT
    c.c_customer_id,
    cad.ca_zip,
    cad.ca_city,
    AVG(yas.avg_sales) AS avg_annual_sales,
    SUM(cs.total_web_sales) AS total_spent
FROM 
    top_customers tc
INNER JOIN customer c ON tc.c_customer_id = c.c_customer_id
INNER JOIN customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
INNER JOIN yearly_average_sales yas ON yas.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
LEFT JOIN customer_sales cs ON cs.c_customer_id = c.c_customer_id
WHERE
    cad.ca_zip IS NOT NULL AND
    tc.rnk <= 10
GROUP BY
    c.c_customer_id, cad.ca_zip, cad.ca_city
ORDER BY
    total_spent DESC;
