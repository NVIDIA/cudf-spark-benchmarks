
WITH sales_summary AS (
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.ss_store_sk, 
        s.ss_item_sk, 
        d.d_year, 
        d.d_month_seq, 
        d.d_quarter_seq
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
top_items AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales_price,
        RANK() OVER (ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
final_summary AS (
    SELECT 
        ss.ss_store_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.hd_income_band_sk,
        ci.hd_buy_potential,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_net_paid) AS total_net_paid,
        ti.total_sales_price
    FROM 
        sales_summary ss
    JOIN 
        customer_info ci ON ci.c_customer_sk = (SELECT MIN(c.c_customer_sk) FROM customer c)
    JOIN 
        top_items ti ON ss.ss_item_sk = ti.ss_item_sk
    GROUP BY 
        ss.ss_store_sk, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_education_status, 
        ci.cd_purchase_estimate, 
        ci.hd_income_band_sk, 
        ci.hd_buy_potential,
        ti.total_sales_price
)
SELECT 
    fs.ss_store_sk,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_education_status,
    fs.cd_purchase_estimate,
    fs.hd_income_band_sk,
    fs.hd_buy_potential,
    fs.total_quantity,
    fs.total_net_paid,
    fs.total_sales_price
FROM 
    final_summary fs
WHERE 
    fs.total_quantity > 100
ORDER BY 
    fs.total_net_paid DESC, 
    fs.total_quantity ASC;
