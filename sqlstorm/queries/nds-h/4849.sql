WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        AVG(s.s_acctbal) AS avg_acct_bal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, n.n_name, r.r_name
), RevenuePerNation AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    sr.region_name,
    sr.nation_name,
    sr.avg_acct_bal,
    COALESCE(rp.total_revenue, 0) AS total_revenue
FROM 
    SupplierRegion sr
LEFT JOIN 
    RevenuePerNation rp ON sr.nation_name = rp.nation_name
WHERE 
    sr.avg_acct_bal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY 
    sr.region_name, rp.total_revenue DESC;