WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.rank <= 10
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supply_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        HighRevenueOrders hro ON l.l_orderkey = hro.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    s.s_name,
    s.total_supply_revenue,
    n.n_name,
    r.r_name
FROM 
    SupplierRevenue s
JOIN 
    supplier sup ON s.s_suppkey = sup.s_suppkey
JOIN 
    nation n ON sup.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.total_supply_revenue > 1000000
ORDER BY 
    s.total_supply_revenue DESC;
