WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1993-01-01' AND DATE '1993-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 1
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    tr.r_name AS region_name,
    sr.s_name AS supplier_name,
    sr.total_supply_cost
FROM 
    RankedOrders t
JOIN 
    TopRegions tr ON t.o_orderkey % 10 = tr.r_regionkey
JOIN 
    SupplierRevenue sr ON sr.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierRevenue)
WHERE 
    t.revenue_rank <= 5
ORDER BY 
    t.total_revenue DESC, t.o_orderdate;
