
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
),
TopSellingItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM
        RankedSales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.sales_rank <= 10
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        c.c_email_address,
        t.total_quantity,
        t.total_sales
    FROM
        TopSellingItems t
    JOIN
        customer c ON t.total_quantity = (SELECT MAX(total_quantity) FROM TopSellingItems) 
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    cd.c_email_address,
    SUM(cd.total_quantity) AS quantity_bought,
    SUM(cd.total_sales) AS total_spent
FROM
    CustomerDetails cd
GROUP BY
    cd.c_customer_id, cd.cd_gender, cd.cd_credit_rating, cd.cd_dep_count, cd.c_email_address
HAVING
    SUM(cd.total_sales) > 1000
ORDER BY
    total_spent DESC;
