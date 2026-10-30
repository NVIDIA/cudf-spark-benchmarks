
WITH  SaleTrends AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_sold_date_sk
    HAVING
        SUM(ws_net_profit) > 1000
),
TopTrends AS (
    SELECT
        st.ws_sold_date_sk,
        st.total_profit,
        st.total_orders,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS rank_profit
    FROM
        (SELECT * FROM SaleTrends WHERE rn <= 10) AS st
),
CustomerPurchases AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        MAX(cd.cd_marital_status) AS marital_status,
        MAX(cd.cd_credit_rating) AS credit_rating
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    cp.total_spent,
    ct.rank_profit,
    CASE 
        WHEN cp.marital_status = 'M' THEN 'Married'
        WHEN cp.marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    CASE 
        WHEN cp.credit_rating = 'Excellent' THEN 'High'
        WHEN cp.credit_rating = 'Good' THEN 'Medium'
        ELSE 'Low'
    END AS credit_rating
FROM
    (SELECT DISTINCT c.c_first_name, c.c_last_name, c.c_customer_sk
     FROM customer c) AS c
JOIN CustomerPurchases cp ON c.c_customer_sk = cp.c_customer_sk
LEFT JOIN TopTrends ct ON ct.ws_sold_date_sk = cp.total_spent
WHERE
    cp.total_spent IS NOT NULL
ORDER BY
    cp.total_spent DESC,
    c.c_first_name ASC,
    c.c_last_name ASC
LIMIT 100;
