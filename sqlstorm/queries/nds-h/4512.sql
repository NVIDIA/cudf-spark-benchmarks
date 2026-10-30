
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartPrices AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighSpenderCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent
    FROM 
        CustomerOrderSummary cs
    JOIN 
        (SELECT c.c_custkey FROM CustomerOrderSummary c WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)) AS high_spenders 
    ON cs.c_custkey = high_spenders.c_custkey
)
SELECT 
    c.c_name AS customer_name,
    c.total_spent AS total_spent,
    COALESCE(sp.total_supply_value, 0) AS total_supply_value,
    ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
FROM 
    HighSpenderCustomers c
LEFT JOIN 
    SupplierPartPrices sp ON c.c_custkey = sp.s_suppkey
WHERE 
    (c.total_spent > 1000 OR c.total_spent IS NULL)
ORDER BY 
    c.total_spent DESC;
