
WITH  SalesTrend AS (
    SELECT
        ws_sold_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_sold_date_sk
    ORDER BY
        ws_sold_date_sk
),
SalesSummary AS (
    SELECT
        d_year,
        SUM(total_orders) AS yearly_orders,
        SUM(total_profit) AS yearly_profit
    FROM
        SalesTrend st
    JOIN date_dim dd ON st.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        d_year
),
CustomerAnalysis AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        cd.cd_marital_status = 'M'
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(ca.ca_gmt_offset) AS total_offset
    FROM
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
    ORDER BY
        total_offset DESC
    LIMIT 10
)
SELECT
    ss.d_year,
    ss.yearly_orders,
    ss.yearly_profit,
    ca.cd_gender,
    ca.order_count,
    ca.total_spent,
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city
FROM
    SalesSummary ss
LEFT JOIN CustomerAnalysis ca ON ca.order_count > 10
JOIN TopCustomers tc ON tc.total_offset > 0
ORDER BY
    ss.d_year DESC, ca.total_spent DESC;
