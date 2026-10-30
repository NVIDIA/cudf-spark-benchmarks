
WITH Total_Sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_coupon_amt) AS total_coupons,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 12 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 12 LIMIT 1) + 30
    GROUP BY 
        ws_bill_customer_sk
),
Customer_Details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        t.total_sales,
        t.order_count,
        t.total_coupons,
        t.avg_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Total_Sales t ON c.c_customer_sk = t.ws_bill_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.total_sales,
    cd.order_count,
    cd.total_coupons,
    cd.avg_net_profit
FROM 
    Customer_Details cd
WHERE 
    cd.total_sales > 5000
ORDER BY 
    cd.avg_net_profit DESC
LIMIT 100;
