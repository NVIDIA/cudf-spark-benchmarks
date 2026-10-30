
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_purchase_estimate,
        COALESCE(NULLIF(cs.purchase_rank, 1), -1) AS rank 
    FROM CustomerStats cs
    WHERE cs.purchase_rank <= 5
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
SalesSummary AS (
    SELECT 
        dd.d_year,
        SUM(sd.total_sales) AS yearly_sales,
        SUM(sd.total_orders) AS yearly_orders,
        AVG(sd.avg_sales_price) AS yearly_avg_sales_price
    FROM date_dim dd
    LEFT JOIN SalesData sd ON dd.d_date_sk = sd.ws_sold_date_sk
    GROUP BY dd.d_year
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(ss.yearly_sales, 0) AS total_sales,
    ss.yearly_orders,
    ss.yearly_avg_sales_price
FROM TopCustomers tc
LEFT JOIN SalesSummary ss ON ss.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE tc.rank <> -1
ORDER BY total_sales DESC, tc.c_last_name ASC;
