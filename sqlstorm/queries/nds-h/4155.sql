
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(ps.ps_supplycost) 
            FROM partsupp ps
            WHERE ps.ps_partkey = p.p_partkey
        )
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    R.p_name,
    R.p_retailprice,
    COALESCE(CO.total_spent, 0) AS customer_spent,
    S.s_name AS supplier_name,
    PS.supplier_count,
    PS.total_supply_cost
FROM 
    RankedParts R
LEFT JOIN CustomerOrders CO ON R.p_partkey = CO.c_custkey
LEFT JOIN TopSuppliers S ON R.p_partkey = S.s_suppkey
JOIN PartSupplierInfo PS ON R.p_partkey = PS.p_partkey
WHERE 
    R.rn = 1
    AND (S.s_name IS NOT NULL OR CO.total_spent > 0)
ORDER BY 
    R.p_retailprice DESC, 
    customer_spent DESC;
