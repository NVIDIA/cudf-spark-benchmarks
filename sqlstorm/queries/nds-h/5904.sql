WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_suppkey
),
RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.o_orderdate,
        os.total_revenue,
        os.part_count,
        os.c_mktsegment,
        RANK() OVER (PARTITION BY os.c_mktsegment ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary os
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    ro.part_count,
    ro.c_mktsegment,
    sr.supplier_revenue
FROM 
    RankedOrders ro
JOIN 
    SupplierRevenue sr ON ro.part_count > 10
WHERE 
    ro.revenue_rank <= 5
ORDER BY 
    ro.c_mktsegment, ro.total_revenue DESC;
