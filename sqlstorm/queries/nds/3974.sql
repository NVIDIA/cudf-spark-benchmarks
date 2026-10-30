
WITH SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_date = DATE('2002-10-01')
        )
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
TopCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales,
        si.order_count,
        si.total_profit,
        DENSE_RANK() OVER (ORDER BY si.total_profit DESC) AS rank_order
    FROM 
        SalesData si
    JOIN 
        CustomerInfo ci ON si.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    tc.order_count,
    tc.total_profit
FROM 
    TopCustomers tc
WHERE 
    tc.rank_order <= 10
ORDER BY 
    tc.total_profit DESC;
