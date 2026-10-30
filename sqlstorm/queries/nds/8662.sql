WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451912 AND 2452275 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
RankedSales AS (
    SELECT 
        cs.*,
        RANK() OVER (PARTITION BY cs.hd_income_band_sk ORDER BY cs.total_sales DESC) AS income_rank
    FROM 
        CustomerSales cs
)
SELECT 
    r.total_sales,
    r.avg_net_paid,
    r.order_count,
    r.cd_gender,
    r.cd_marital_status,
    r.hd_income_band_sk,
    COUNT(*) AS customer_count
FROM 
    RankedSales r
WHERE 
    r.income_rank <= 5
GROUP BY 
    r.total_sales, r.avg_net_paid, r.order_count, r.cd_gender, r.cd_marital_status, r.hd_income_band_sk
ORDER BY 
    r.hd_income_band_sk, r.total_sales DESC;