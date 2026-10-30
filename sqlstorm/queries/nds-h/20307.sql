WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 100000
),
SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size IS NOT NULL AND (s.s_acctbal IS NULL OR s.s_acctbal > 0)
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_nationkey
)
SELECT 
    r.r_name AS region_name,
    nc.n_name AS nation_name,
    COUNT(DISTINCT hc.c_custkey) AS high_value_customer_count,
    SUM(sps.ps_availqty) AS total_available_parts,
    AVG(ts.avg_cost) AS average_supplier_cost
FROM 
    region r
LEFT JOIN 
    nation nc ON r.r_regionkey = nc.n_regionkey
LEFT JOIN 
    HighValueCustomers hc ON nc.n_nationkey = hc.c_custkey
LEFT JOIN 
    SupplierParts sps ON sps.ps_availqty IS NOT NULL
LEFT JOIN 
    TopSuppliers ts ON ts.s_nationkey = nc.n_nationkey
WHERE 
    EXISTS (SELECT 1 FROM RankedOrders ro WHERE ro.o_custkey = hc.c_custkey AND ro.rn = 1)
GROUP BY 
    r.r_name, nc.n_name
HAVING 
    COUNT(DISTINCT hc.c_custkey) > 0 AND AVG(ts.avg_cost) IS NOT NULL
ORDER BY 
    region_name, nation_name;
