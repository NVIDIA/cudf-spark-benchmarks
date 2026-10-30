
WITH  CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT wr_order_number) AS web_returns_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_returns,
    cs.total_orders,
    cs.web_returns_count,
    ss.total_web_sales,
    ss.total_web_orders,
    CASE 
        WHEN cs.total_orders > 10 THEN 'High Value'
        WHEN cs.total_orders BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesSummary ss ON cs.c_customer_sk = ss.c_customer_sk
WHERE 
    cs.sales_rank <= 10 AND cs.total_returns > 0
ORDER BY 
    total_web_sales DESC, cs.c_last_name, cs.c_first_name;
