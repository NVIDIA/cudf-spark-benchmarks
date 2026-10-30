WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name
    FROM 
        SupplierDetails sd
    WHERE 
        sd.avg_acct_balance > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    r.r_name,
    COALESCE(SUM(ro.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT hvs.s_suppkey) AS unique_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
WHERE 
    (c.c_acctbal IS NOT NULL AND c.c_acctbal > 0)
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1997-12-31'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;