WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 5000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    ns.n_name AS nation_name,
    hs.total_revenue,
    COUNT(DISTINCT hs.o_orderkey) AS order_count,
    SUM(s.ps_supplycost) AS total_supply_cost,
    SUM(s.ps_availqty) AS total_available_qty
FROM 
    HighValueOrders hs
JOIN 
    nation ns ON hs.c_nationkey = ns.n_nationkey
JOIN 
    RankedSuppliers s ON hs.o_orderkey = s.s_suppkey
GROUP BY 
    ns.n_name, hs.total_revenue
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 10;