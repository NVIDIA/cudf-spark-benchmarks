
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
IncomeBandSales AS (
    SELECT 
        h.hd_income_band_sk,
        SUM(CASE WHEN cs.total_sales IS NOT NULL THEN cs.total_sales ELSE 0 END) AS total_income
    FROM 
        household_demographics h
    LEFT JOIN 
        (SELECT 
            c.c_customer_sk, 
            c.c_current_hdemo_sk, 
            cs.total_sales 
         FROM 
            CustomerSales cs
         JOIN 
            customer c ON cs.c_customer_sk = c.c_customer_sk) cs ON h.hd_demo_sk = cs.c_current_hdemo_sk
    GROUP BY 
        h.hd_income_band_sk
),
SalesRanked AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        isb.total_income,
        RANK() OVER (ORDER BY isb.total_income DESC) AS income_rank
    FROM 
        IncomeBandSales isb
    JOIN 
        income_band ib ON isb.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ir.income_rank,
    ir.ib_lower_bound,
    ir.ib_upper_bound,
    ir.total_income
FROM 
    SalesRanked ir
WHERE 
    ir.income_rank <= 10
ORDER BY 
    ir.income_rank;
