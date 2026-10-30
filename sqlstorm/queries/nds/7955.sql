
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk >= 2450000 AND ws.ws_sold_date_sk <= 2450500
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk, hd.hd_buy_potential
),
RankedSales AS (
    SELECT 
        cs.*, 
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    r.cd_gender,
    COUNT(r.c_customer_sk) AS ranked_customer_count,
    AVG(r.total_sales) AS avg_total_sales,
    AVG(r.order_count) AS avg_order_count,
    MAX(r.total_sales) AS max_sales,
    (SELECT SUM(total_sales) FROM RankedSales) AS grand_total_sales
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.cd_gender
ORDER BY 
    r.cd_gender;
