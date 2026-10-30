WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sp.total_availqty
    FROM 
        supplier s
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    WHERE 
        sp.total_availqty > 100
)
SELECT 
    r.r_name,
    n.n_name,
    p.p_name,
    COUNT(*) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    r.r_name IS NOT NULL
    AND (o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' OR o.o_orderdate IS NULL)
    AND (s.s_nationkey IN (SELECT DISTINCT n_nationkey FROM nation WHERE n_name LIKE 'USA%'))
GROUP BY 
    r.r_name, n.n_name, p.p_name
ORDER BY 
    total_orders DESC, total_revenue DESC
LIMIT 100;