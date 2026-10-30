
WITH RankedSales AS (
    SELECT
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_net_profit) DESC) AS item_rank
    FROM
        store_sales s
    JOIN
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE
        cd.cd_gender = 'F' 
        AND d.d_year = 2023
        AND (cd.cd_marital_status = 'M' OR cd.cd_education_status LIKE '%graduate%')
    GROUP BY
        s.ss_sold_date_sk, s.ss_item_sk
),
TopSales AS (
    SELECT
        rs.ss_item_sk,
        rs.total_quantity,
        rs.total_profit
    FROM
        RankedSales rs
    WHERE
        rs.item_rank <= 10
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_profit
FROM
    TopSales ts
JOIN
    item i ON ts.ss_item_sk = i.i_item_sk
ORDER BY
    ts.total_profit DESC;
