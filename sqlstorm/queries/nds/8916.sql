
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        cd_gender,
        cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk, cd_gender, cd_marital_status
),
RankedSales AS (
    SELECT 
        customer_sk,
        total_sales,
        total_profit,
        order_count,
        cd_gender,
        cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.customer_sk,
    r.total_sales,
    r.total_profit,
    r.order_count,
    r.cd_gender,
    r.cd_marital_status
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.cd_gender, r.total_sales DESC;
