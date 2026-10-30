WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
), LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    COALESCE(f.s_name, 'No Supplier') AS supplier_name,
    COALESCE(l.total_revenue, 0) AS order_revenue,
    f.total_supplycost,
    r.order_rank,
    CASE 
        WHEN r.order_rank = 1 THEN 'Most Recent Order'
        ELSE 'Older Order'
    END AS order_age
FROM 
    RankedOrders r
LEFT JOIN 
    FilteredSuppliers f ON r.o_custkey = f.s_suppkey
LEFT JOIN 
    LineItemAggregates l ON r.o_orderkey = l.l_orderkey
WHERE 
    r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
    AND r.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
ORDER BY 
    r.o_orderdate DESC, f.total_supplycost DESC;