WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < DATE '1997-01-01')
), 
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        FilteredOrders fo ON c.c_custkey = fo.o_custkey
    JOIN 
        lineitem lo ON fo.o_orderkey = lo.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    n.n_name,
    r.r_name,
    cs.c_name,
    cs.total_spent,
    rs.s_name AS top_supplier,
    rs.total_supply_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerSpending cs ON n.n_nationkey = cs.c_custkey 
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey 
WHERE 
    (cs.total_spent IS NOT NULL OR rs.total_supply_cost IS NULL) 
    AND (n.n_name LIKE 'A%' OR r.r_name LIKE '%East%')
ORDER BY 
    total_spent DESC, top_supplier ASC
LIMIT 
    10;