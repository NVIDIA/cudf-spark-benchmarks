WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1994-01-01' AND o.o_orderdate < '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn = 1 AND ro.total_revenue IS NOT NULL
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 0 AND s.s_name NOT LIKE '%obsolete%'
),
FilteredSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.s_name, 
        ps.s_acctbal,
        COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS total_discount
    FROM 
        PartSuppliers ps
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        ps.supplier_rank <= 3
    GROUP BY 
        ps.ps_partkey, ps.s_name, ps.s_acctbal
)
SELECT 
    p.p_name, 
    fs.s_name,
    fs.total_discount,
    COUNT(DISTINCT ho.o_orderkey) AS order_count,
    COUNT(CASE WHEN ho.total_revenue IS NOT NULL THEN 1 END) AS high_revenue_count
FROM 
    part p
JOIN 
    FilteredSuppliers fs ON p.p_partkey = fs.ps_partkey
FULL OUTER JOIN 
    HighRevenueOrders ho ON ho.o_orderkey = fs.ps_partkey
WHERE 
    p.p_retailprice > 20.00 
    AND (fs.total_discount IS NULL OR fs.total_discount < 1000)
GROUP BY 
    p.p_name, fs.s_name, fs.total_discount
HAVING 
    COUNT(DISTINCT ho.o_orderkey) > 0
ORDER BY 
    p.p_name, fs.total_discount DESC
LIMIT 50;
