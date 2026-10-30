
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY
        ss_store_sk, ss_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_current_addr_sk) AS address_count,
        MAX(c.c_birth_year) AS max_birth_year
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT
        rs.ss_item_sk,
        rs.total_quantity,
        rs.total_net_paid
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank <= 5
    UNION ALL
    SELECT
        rs.ss_item_sk,
        NULLIF(rs.total_quantity, 0) AS total_quantity, 
        rs.total_net_paid
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank > 5
)
SELECT
    ci.c_customer_id,
    ci.cd_gender,
    ti.total_quantity,
    ti.total_net_paid,
    CASE
        WHEN ci.address_count IS NULL THEN 'UNKNOWN ADDRESS'
        ELSE CAST(ci.address_count AS VARCHAR(255))
    END AS address_count_display,
    COALESCE(ti.total_net_paid, 0) AS net_paid_fallback,
    CASE 
        WHEN ci.max_birth_year IS NULL THEN 'UNSPECIFIED'
        WHEN ci.max_birth_year < 1950 THEN 'SENIOR'
        ELSE 'GENERATION X'
    END AS customer_age_group
FROM
    CustomerInfo ci
LEFT JOIN
    TopItems ti ON ci.c_customer_id IN (
        SELECT c.c_customer_id
        FROM web_sales ws
        LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        WHERE ws.ws_item_sk = ti.ss_item_sk
    )
WHERE
    (ci.address_count IS NOT NULL OR ti.total_quantity IS NOT NULL)
    AND ci.cd_marital_status IN ('M', 'S')
ORDER BY
    ci.cd_gender ASC,
    ti.total_net_paid DESC NULLS LAST;
