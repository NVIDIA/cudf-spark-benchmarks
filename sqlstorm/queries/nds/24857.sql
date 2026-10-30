
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        COUNT(*) OVER(PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk) AS return_count,
        SUM(sr_return_amt) OVER(PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
),
TopCustomers AS (
    SELECT 
        sr_customer_sk,
        NTILE(10) OVER (ORDER BY total_return_amt DESC) AS income_bracket
    FROM 
        RankedReturns
    WHERE 
        return_count > 1
),
AggregateSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_customer_sk IN (SELECT sr_customer_sk FROM TopCustomers WHERE income_bracket = 1)
    GROUP BY 
        c.c_customer_sk
),
FinalOutput AS (
    SELECT 
        a.c_customer_sk,
        a.total_sales,
        a.order_count,
        a.avg_net_profit,
        CASE 
            WHEN a.total_sales > 5000 THEN 'High Spender' 
            ELSE 'Low Spender' 
        END AS customer_type,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
    FROM 
        AggregateSales a
    LEFT JOIN 
        customer_demographics cd ON a.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    f.c_customer_sk,
    f.total_sales,
    f.order_count,
    f.avg_net_profit,
    f.customer_type,
    f.gender,
    f.marital_status,
    w.w_warehouse_name
FROM 
    FinalOutput f
LEFT JOIN 
    warehouse w ON f.c_customer_sk = w.w_warehouse_sk
WHERE 
    f.total_sales IS NOT NULL
    AND (f.customer_type = 'High Spender' OR f.gender = 'M')
ORDER BY 
    f.total_sales DESC
LIMIT 20;

