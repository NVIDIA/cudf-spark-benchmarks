
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_ship_date_sk IS NOT NULL
    GROUP BY
        ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
    WHERE
        sd.total_sales > 1000
),
TopCustomers AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.rn
    FROM
        RankedCustomers rc
    WHERE
        rc.rn <= 10
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    ts.total_sales,
    ts.order_count,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No sales'
        ELSE 'Sales present'
    END AS sales_status,
    COALESCE(ts.sales_rank, 0) AS sales_rank
FROM
    TopCustomers tc
LEFT JOIN
    TopSales ts ON tc.c_customer_sk = (
        SELECT 
            ws_bill_customer_sk
        FROM 
            web_sales
        WHERE 
            ws_item_sk IN (
                SELECT i_item_sk FROM item WHERE i_brand_id IN (
                    SELECT DISTINCT i_brand_id FROM item WHERE i_current_price > 50
                )
            )
        GROUP BY ws_bill_customer_sk
        ORDER BY SUM(ws_net_paid) DESC
        LIMIT 1
    )
ORDER BY
    tc.c_customer_sk;
