
WITH CustomerCity AS (
    SELECT
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_address
    JOIN
        customer ON customer.c_current_addr_sk = ca_address_sk
    GROUP BY
        ca_city
),
ItemBrand AS (
    SELECT
        i_brand,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    JOIN
        item ON web_sales.ws_item_sk = item.i_item_sk
    GROUP BY
        i_brand
),
TopCities AS (
    SELECT
        ca_city,
        customer_count,
        RANK() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM
        CustomerCity
),
TopBrands AS (
    SELECT
        i_brand,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS brand_rank
    FROM
        ItemBrand
)
SELECT
    T1.ca_city,
    T1.customer_count,
    T2.i_brand,
    T2.total_sales
FROM
    TopCities T1
JOIN
    TopBrands T2 ON T1.city_rank = T2.brand_rank
WHERE
    T1.city_rank <= 10 AND T2.brand_rank <= 10
ORDER BY
    T1.customer_count DESC, T2.total_sales DESC;
