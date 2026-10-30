
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
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
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY total_sales DESC) as rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name, 
        ci.c_last_name, 
        sd.total_sales, 
        sd.total_orders, 
        sd.avg_net_profit
    FROM 
        CustomerInfo ci 
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        ci.rank <= 5
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    COALESCE(tc.avg_net_profit, 0) AS avg_net_profit,
    CASE 
        WHEN tc.avg_net_profit > 100 THEN 'High Profit'
        WHEN tc.avg_net_profit BETWEEN 50 AND 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA' OR ca.ca_state IS NULL
ORDER BY 
    total_sales DESC, tc.c_last_name ASC;
