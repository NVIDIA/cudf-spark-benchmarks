
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    r.r_name, 
    p.p_name, 
    COALESCE(AVG(ps.ps_supplycost), 0) AS avg_supply_cost,
    COALESCE(SUM(CASE WHEN li.l_discount > 0 THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END), 0) AS total_discounted_sales,
    COALESCE(HVC.total_spent, 0) AS total_spent
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    HighValueCustomers HVC ON HVC.c_custkey = li.l_orderkey 
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    r.r_name, p.p_name, HVC.total_spent
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    r.r_name, total_discounted_sales DESC;
