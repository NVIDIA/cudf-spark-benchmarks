
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM
        customer AS c
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics AS cd
    JOIN household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Sales_By_Demographics AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
        SUM(cs.total_store_sales) AS store_sales,
        SUM(cs.total_web_sales) AS web_sales,
        AVG(cs.web_order_count) AS avg_web_orders,
        AVG(cs.store_order_count) AS avg_store_orders
    FROM
        Customer_Sales AS cs
    JOIN Demographics AS d ON cs.c_customer_sk = d.cd_demo_sk
    WHERE 
        cs.total_store_sales > 0 OR cs.total_web_sales > 0
    GROUP BY d.cd_gender, d.cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    num_customers,
    store_sales,
    web_sales,
    avg_web_orders,
    avg_store_orders
FROM 
    Sales_By_Demographics
ORDER BY store_sales DESC, web_sales DESC;
