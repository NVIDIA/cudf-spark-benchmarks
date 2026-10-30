
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_by_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionRevenue AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(o.total_revenue) AS region_revenue
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rr.r_name AS region, 
    rr.region_revenue, 
    sr.s_name AS supplier, 
    sr.supplier_revenue
FROM 
    RegionRevenue rr
JOIN 
    SupplierRevenue sr ON rr.region_revenue = sr.supplier_revenue
WHERE 
    rr.region_revenue > (SELECT AVG(region_revenue) FROM RegionRevenue)
ORDER BY 
    rr.region_revenue DESC, sr.supplier_revenue DESC;
