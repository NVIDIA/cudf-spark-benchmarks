
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
    HAVING
        SUM(ws_quantity) > 0
),
TopItems AS (
    SELECT
        s.ws_item_sk,
        c.c_customer_id,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY SUM(s.ws_ext_sales_price) DESC) AS item_rank
    FROM
        web_sales s
    JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        s.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        s.ws_item_sk, c.c_customer_id, ca.ca_city
)
SELECT
    ti.ws_item_sk,
    ci.c_customer_id,
    COALESCE(ca.ca_city, 'UNKNOWN') AS city,
    d.d_year AS sales_year,
    SUM(CASE WHEN d.d_year = 2022 THEN ti.ws_ext_sales_price ELSE 0 END) AS sales_in_2022,
    SUM(ti.ws_ext_sales_price) AS total_sales
FROM 
    web_sales ti
JOIN 
    TopItems ci ON ti.ws_item_sk = ci.ws_item_sk
LEFT JOIN
    customer_address ca ON ti.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN 
    date_dim d ON ti.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    ti.ws_item_sk, ci.c_customer_id, ca.ca_city, d.d_year
HAVING 
    SUM(ti.ws_quantity) > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
