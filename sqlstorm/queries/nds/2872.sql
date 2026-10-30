
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesStatistics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No sales'
            WHEN cs.total_sales < 1000 THEN 'Low spender'
            WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium spender'
            ELSE 'High spender'
        END AS spending_category
    FROM 
        CustomerSales cs
    WHERE 
        cs.order_count > 0
),
TopSpenders AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_sales,
        s.order_count,
        s.sales_rank,
        s.spending_category
    FROM 
        SalesStatistics s
    WHERE 
        s.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_customer_sk = h.hd_demo_sk
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    t.spending_category,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_purchase_estimate,
    d.hd_buy_potential
FROM 
    TopSpenders t
LEFT JOIN 
    CustomerDemographics d ON t.c_customer_sk = d.c_customer_sk
WHERE 
    (d.cd_gender IS NOT NULL OR d.cd_marital_status IS NOT NULL)
ORDER BY 
    t.total_sales DESC, d.cd_purchase_estimate DESC;
