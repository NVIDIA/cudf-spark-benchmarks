WITH SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    sr.s_name AS top_supplier,
    sr.total_supply_cost
FROM 
    CustomerOrderStats co
LEFT JOIN 
    SupplierRanking sr ON sr.rank = 1
WHERE 
    co.order_count > 5
  AND 
    (co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats WHERE order_count > 0) 
     OR co.total_spent IS NULL)
ORDER BY 
    co.total_spent DESC;

