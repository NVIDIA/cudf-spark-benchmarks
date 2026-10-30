
WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        w.w_warehouse_id
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS customer_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
analytics AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.customer_net_profit,
        ss.total_net_profit,
        ss.total_sales,
        ss.total_quantity_sold,
        (cs.customer_net_profit / NULLIF(ss.total_sales, 0)) AS avg_profit_per_sale
    FROM 
        customer_info cs
    JOIN 
        sales_summary ss ON cs.customer_net_profit > (ss.total_net_profit * 0.1)
)
SELECT 
    a.c_customer_id,
    a.cd_gender,
    a.cd_marital_status,
    a.customer_net_profit,
    a.total_net_profit,
    a.total_sales,
    a.total_quantity_sold,
    CASE 
        WHEN a.avg_profit_per_sale IS NULL THEN 'No Sales'
        ELSE CAST(a.avg_profit_per_sale AS STRING)
    END AS avg_profit_per_sale_formatted
FROM 
    analytics a
WHERE 
    a.customer_net_profit < (SELECT AVG(customer_net_profit) FROM customer_info)
ORDER BY 
    a.total_net_profit DESC
LIMIT 50;
