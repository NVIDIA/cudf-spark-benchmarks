WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), RevenueByNation AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ro.total_revenue) AS nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank = 1
    GROUP BY 
        n.n_name
), SupplierStats AS (
    SELECT 
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
), FinalStats AS (
    SELECT 
        rbn.nation_name,
        COALESCE(rbn.nation_revenue, 0) AS total_revenue,
        ss.supplier_name,
        ss.part_count,
        ss.total_cost
    FROM 
        RevenueByNation rbn
    FULL OUTER JOIN 
        SupplierStats ss ON rbn.nation_name = ss.supplier_name
)
SELECT 
    nation_name,
    total_revenue,
    supplier_name,
    part_count,
    total_cost
FROM 
    FinalStats
ORDER BY 
    total_revenue DESC, part_count DESC;