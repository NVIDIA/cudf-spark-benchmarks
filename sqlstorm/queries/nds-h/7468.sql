WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_mktsegment, 
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
), 
TopProducts AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey 
    WHERE 
        ro.price_rank <= 10
    GROUP BY 
        l.l_partkey
), 
PopularParts AS (
    SELECT 
        p.p_name, 
        p.p_type, 
        tp.total_revenue
    FROM 
        part p
    JOIN 
        TopProducts tp ON p.p_partkey = tp.l_partkey
), 
RegionDetails AS (
    SELECT 
        r.r_name, 
        SUM(tp.total_revenue) AS region_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        TopProducts tp ON ps.ps_partkey = tp.l_partkey
    GROUP BY 
        r.r_name
)
SELECT 
    rd.r_name, 
    rd.region_revenue,
    pp.p_name, 
    pp.total_revenue
FROM 
    RegionDetails rd 
JOIN 
    PopularParts pp ON rd.r_name = pp.p_type
ORDER BY 
    rd.region_revenue DESC, pp.total_revenue DESC;