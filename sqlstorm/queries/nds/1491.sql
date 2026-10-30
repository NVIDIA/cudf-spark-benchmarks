
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchase_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_purchase_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerIncome AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_demo_sk, h.hd_income_band_sk
),
RankedCustomerSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.store_purchase_count,
        cs.catalog_purchase_count,
        cs.web_purchase_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    rcs.c_first_name,
    rcs.c_last_name,
    rcs.total_spent,
    rcs.store_purchase_count,
    rcs.catalog_purchase_count,
    rcs.web_purchase_count,
    ci.customer_count,
    CASE 
        WHEN rcs.total_spent >= 500 THEN 'High Spender'
        WHEN rcs.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    RankedCustomerSales rcs
LEFT JOIN 
    CustomerIncome ci ON rcs.c_customer_sk = ci.hd_demo_sk
WHERE 
    rcs.sales_rank <= 100
    AND (rcs.total_spent IS NOT NULL OR ci.customer_count > 0)
ORDER BY 
    rcs.total_spent DESC;
