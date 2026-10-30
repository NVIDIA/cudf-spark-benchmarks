
WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name, 
    p.p_brand, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS revenue_rank,
    (SELECT COUNT(DISTINCT n.n_nationkey) FROM nation n WHERE n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s LEFT JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey)) AS supplier_nation_count
FROM 
    part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
LEFT JOIN CustomerOrders co ON co.order_count > 0
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 20.00) 
    AND p.p_comment NOT LIKE '%obsolete%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 5000
ORDER BY 
    revenue DESC;
