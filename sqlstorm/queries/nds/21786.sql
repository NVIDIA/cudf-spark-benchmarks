
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ss_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        cd.cd_gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buying_power,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_summary AS (
    SELECT 
        si.ss_store_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.buying_power,
        SUM(si.ss_net_profit) AS total_profit
    FROM 
        store_sales si
    JOIN 
        customer_info ci ON si.ss_customer_sk = ci.c_customer_sk
    WHERE 
        ci.buying_power IS NOT NULL
    GROUP BY 
        si.ss_store_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.buying_power
),
final_summary AS (
    SELECT 
        ss.ss_store_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.cd_gender,
        ss.buying_power,
        ss.total_profit,
        rs.total_sales,
        CASE 
            WHEN ss.total_profit > 10000 THEN 'High Performer'
            WHEN ss.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM 
        sales_summary ss
    LEFT JOIN 
        ranked_sales rs ON ss.ss_store_sk = rs.ss_store_sk
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    fs.ss_store_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.cd_gender,
    fs.buying_power,
    fs.total_profit,
    fs.total_sales,
    fs.performance_category
FROM 
    final_summary fs
WHERE 
    (fs.buying_power IS NULL OR fs.performance_category != 'Low Performer')
ORDER BY 
    fs.total_profit DESC, fs.total_sales ASC
LIMIT 10;
