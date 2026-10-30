
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        i.i_brand,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, i.i_brand
),
returns_info AS (
    SELECT
        cr_returning_customer_sk,
        COUNT(cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_quantity) AS avg_return_quantity
    FROM
        catalog_returns
    WHERE
        cr_return_quantity IS NOT NULL
    GROUP BY
        cr_returning_customer_sk
),
special_cases AS (
    SELECT
        ci.full_name,
        COALESCE(ri.return_count, 0) AS return_count,
        ci.total_quantity,
        ci.total_net_paid,
        ci.gender_rank,
        CASE 
            WHEN ci.gender_rank = 1 AND ri.return_count > 5 THEN 'VIP'
            WHEN ci.gender_rank = 1 AND ri.return_count <= 5 THEN 'Gold'
            WHEN ci.gender_rank > 1 AND ci.total_net_paid > 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier,
        CASE
            WHEN ci.cd_marital_status = 'M' THEN 'Married'
            WHEN ci.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status
    FROM
        customer_info ci
    LEFT JOIN
        returns_info ri ON ci.c_customer_sk = ri.cr_returning_customer_sk
)
SELECT
    *,
    CASE
        WHEN return_count > total_quantity THEN 'Returned More Items than Bought'
        ELSE 'Normal'
    END AS return_status
FROM
    special_cases
WHERE
    (gender_rank = 1 AND customer_tier = 'VIP') OR
    (return_count > 0 AND total_net_paid < 500)
ORDER BY
    customer_tier DESC,
    total_net_paid ASC;
