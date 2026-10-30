
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender
), 
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.total_sales,
        cs.average_profit,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
TopSales AS (
    SELECT 
        ts.c_customer_id,
        ts.cd_gender,
        ts.total_sales,
        ts.average_profit
    FROM 
        SalesSummary ts
    WHERE 
        ts.sales_rank <= 10
)
SELECT 
    ts.c_customer_id,
    ts.cd_gender,
    ts.total_sales,
    ts.average_profit,
    CASE 
        WHEN ts.total_sales > 1000 THEN 'High Value'
        WHEN ts.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    CASE 
        WHEN ts.average_profit IS NULL THEN 'No Profit Data'
        ELSE 'Profit Data Available'
    END AS profit_status
FROM 
    TopSales ts
ORDER BY 
    ts.cd_gender, ts.total_sales DESC;
