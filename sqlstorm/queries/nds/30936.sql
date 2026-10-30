
WITH  SalesGrowth AS (
    SELECT 
        ws_sold_date_sk, 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM d.d_date) ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_sold_date_sk, EXTRACT(YEAR FROM d.d_date)
),
TopGrowth AS (
    SELECT 
        sales_year, 
        total_sales
    FROM 
        SalesGrowth
    WHERE 
        sales_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
StoreSalesStats AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk IS NOT NULL
    GROUP BY 
        s.s_store_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.marital_status,
    ci.total_purchases,
    ci.total_orders,
    sg.sales_year,
    sg.total_sales AS growth_sales,
    ss.total_net_profit,
    ss.avg_sales_price
FROM 
    CustomerInfo ci
JOIN 
    StoreSalesStats ss ON ci.c_customer_sk = ss.s_store_sk
LEFT JOIN 
    TopGrowth sg ON sg.sales_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE 
    ci.total_orders > 0
ORDER BY 
    sg.total_sales DESC, ci.total_purchases DESC
LIMIT 100;
