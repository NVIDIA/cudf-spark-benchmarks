WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2457300 
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
), CTE_IncomeBand AS (
    SELECT
        h.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        household_demographics h
    JOIN
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
), RankedCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        COALESCE(i.ib_income_band_sk, -1) AS income_band, 
        RANK() OVER (PARTITION BY COALESCE(i.ib_income_band_sk, -1) ORDER BY total_spent DESC) AS sales_rank
    FROM
        CustomerSales cs
    LEFT JOIN
        CTE_IncomeBand i ON cs.c_customer_sk = i.hd_demo_sk
)
SELECT
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    rc.total_orders,
    rc.income_band,
    rc.sales_rank
FROM
    RankedCustomers rc
WHERE
    rc.sales_rank <= 10
ORDER BY
    rc.income_band ASC, rc.total_spent DESC;