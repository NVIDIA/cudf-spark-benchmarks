
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
        AND o.o_orderstatus IN ('O', 'F')
),
TotalLineItem AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        FilteredOrders fo ON l.l_orderkey = fo.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    rs.s_name AS top_supplier_name,
    rs.s_acctbal AS top_supplier_balance,
    COUNT(DISTINCT fo.o_orderkey) AS orders_count,
    SUM(tli.total_revenue) AS total_revenue
FROM 
    RankedSuppliers rs
LEFT JOIN 
    TotalLineItem tli ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
            SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100
        )
    )
LEFT JOIN 
    FilteredOrders fo ON tli.l_orderkey = fo.o_orderkey
JOIN 
    nation n ON rs.nation_name = n.n_name
WHERE 
    rs.rn = 1
GROUP BY 
    n.n_name, rs.s_name, rs.s_acctbal
ORDER BY 
    total_revenue DESC, orders_count DESC;
