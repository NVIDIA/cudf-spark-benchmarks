
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count 
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FrequentReturners AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_returned_quantity,
        total_return_amt,
        return_count,
        RANK() OVER (ORDER BY total_return_amt DESC) AS rank_return
    FROM 
        CustomerReturns
    WHERE 
        total_returned_quantity > (SELECT AVG(total_returned_quantity) FROM CustomerReturns)
),
PromotionsUsed AS (
    SELECT 
        w.ws_bill_customer_sk,
        COUNT(DISTINCT w.ws_order_number) AS promotions_used_count,
        SUM(w.ws_net_paid_inc_tax) AS total_sales_amt
    FROM 
        web_sales w
    JOIN 
        promotion p ON w.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        w.ws_bill_customer_sk
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    COALESCE(pr.total_sales_amt, 0) AS total_spent,
    fr.total_returned_quantity,
    fr.return_count,
    (CASE 
        WHEN fr.return_count > 0 THEN 'Frequent Returner' 
        ELSE 'Regular Customer' 
     END) AS customer_type,
    (CASE 
        WHEN fr.total_returned_quantity > 100 THEN 'High Risk'
        ELSE 'Low Risk'
     END) AS return_risk_category
FROM 
    FrequentReturners fr
LEFT JOIN 
    PromotionsUsed pr ON fr.c_customer_sk = pr.ws_bill_customer_sk
WHERE 
    fr.rank_return <= 10
ORDER BY 
    fr.total_return_amt DESC;
