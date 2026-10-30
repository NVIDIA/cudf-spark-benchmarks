WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_address, 
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal < 5000 AND 
        c.c_mktsegment = 'BUILDING'
), DateFilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_custkey
    FROM 
        orders o
    JOIN 
        FilteredCustomers c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), LineItemAggregates AS (
    SELECT 
        lo.l_orderkey, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    rf.s_name AS supplier_name, 
    COUNT(DISTINCT dfo.o_orderkey) AS order_count, 
    SUM(l.total_revenue) AS total_revenue_generated
FROM 
    RankedSuppliers rf
LEFT JOIN 
    DateFilteredOrders dfo ON dfo.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')))
LEFT JOIN 
    LineItemAggregates l ON l.l_orderkey = dfo.o_orderkey
WHERE 
    rf.part_count > 5
GROUP BY 
    rf.s_name
ORDER BY 
    total_revenue_generated DESC
LIMIT 10;