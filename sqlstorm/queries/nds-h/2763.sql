
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name, c.c_nationkey
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.c_custkey,
        ro.c_name,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
)
SELECT 
    fo.c_name AS customer_name,
    fo.total_revenue AS total_revenue,
    sd.s_name AS supplier_name,
    sd.total_available,
    sd.max_cost
FROM 
    FilteredOrders fo
JOIN 
    lineitem l ON fo.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails sd ON l.l_partkey = sd.ps_partkey
WHERE 
    fo.total_revenue > (
        SELECT AVG(total_revenue) 
        FROM FilteredOrders
    )
ORDER BY 
    fo.total_revenue DESC, sd.max_cost ASC;
