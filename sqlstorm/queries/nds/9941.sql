
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(CASE WHEN cd.cd_gender = 'F' THEN ws.ws_sales_price END) AS avg_female_sales,
        AVG(CASE WHEN cd.cd_gender = 'M' THEN ws.ws_sales_price END) AS avg_male_sales
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk
),
TopCustomers AS (
    SELECT
        c_customer_sk,
        total_orders,
        total_profit,
        total_sales,
        avg_female_sales,
        avg_male_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        CustomerSales
),
SalesAnalytics AS (
    SELECT
        tc.c_customer_sk,
        tc.total_orders,
        tc.total_profit,
        tc.total_sales,
        tc.avg_female_sales,
        tc.avg_male_sales,
        td.d_year,
        td.d_month_seq,
        td.d_week_seq
    FROM
        TopCustomers tc
    JOIN
        date_dim td ON EXTRACT(YEAR FROM td.d_date) = EXTRACT(YEAR FROM DATE '2002-10-01') 
                   AND EXTRACT(MONTH FROM td.d_date) = EXTRACT(MONTH FROM DATE '2002-10-01')
    WHERE
        tc.sales_rank <= 100
)
SELECT
    sa.c_customer_sk,
    sa.total_orders,
    sa.total_profit,
    sa.total_sales,
    sa.avg_female_sales,
    sa.avg_male_sales,
    sa.d_year,
    sa.d_month_seq,
    sa.d_week_seq,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS yearly_profit_rank
FROM
    SalesAnalytics sa
ORDER BY
    sa.total_sales DESC
LIMIT 50;
