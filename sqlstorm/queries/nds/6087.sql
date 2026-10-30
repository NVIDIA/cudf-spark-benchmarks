WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458100 AND 2458108  
    GROUP BY 
        ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_revenue,
        cs.total_spent,
        cs.num_purchases,
        RANK() OVER (ORDER BY ss.total_revenue DESC) as revenue_rank
    FROM 
        SalesSummary ss
    JOIN 
        CustomerSummary cs ON ss.ws_item_sk = cs.c_customer_sk  
    WHERE 
        cs.num_purchases > 5  
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_revenue,
    ti.total_spent,
    ti.num_purchases,
    ti.revenue_rank
FROM 
    TopItems ti
WHERE 
    ti.revenue_rank <= 10  
ORDER BY 
    ti.total_revenue DESC;