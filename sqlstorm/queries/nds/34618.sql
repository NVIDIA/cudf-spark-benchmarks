
WITH  Sales_Analysis AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Sales_Summary AS (
    SELECT 
        sa.ws_item_sk,
        SUM(sa.ws_quantity) AS total_quantity,
        SUM(sa.ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT sa.ws_net_paid) AS unique_net_paid_count
    FROM 
        Sales_Analysis sa
    GROUP BY 
        sa.ws_item_sk
),
Top_Customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ss.total_sales_price) AS total_spent,
        COUNT(DISTINCT ss.ws_item_sk) AS items_purchased
    FROM 
        Customer_Info ci
    JOIN 
        Sales_Summary ss ON ci.c_customer_sk = ss.ws_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    HAVING 
        SUM(ss.total_sales_price) > 1000
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    tc.total_spent,
    tc.items_purchased
FROM 
    Customer_Info ci
JOIN 
    Top_Customers tc ON ci.c_customer_sk = tc.c_customer_sk
ORDER BY 
    tc.total_spent DESC;
