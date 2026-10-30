WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopRevenueByStatus AS (
    SELECT 
        o_orderstatus,
        SUM(total_revenue) AS total_per_status
    FROM 
        RankedOrders
    WHERE 
        rank <= 5
    GROUP BY 
        o_orderstatus
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(t.total_per_status) AS total_high_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    TopRevenueByStatus t ON t.o_orderstatus = p.p_comment
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_high_revenue DESC;
