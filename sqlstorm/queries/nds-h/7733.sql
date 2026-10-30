WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
        AND s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RegionRevenue AS (
    SELECT 
        r.r_name,
        SUM(sos.total_revenue) AS total_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierOrderSummary sos ON n.n_name = sos.nation_name
    GROUP BY 
        r.r_name
)
SELECT 
    rr.r_name,
    rr.total_revenue,
    ROW_NUMBER() OVER (ORDER BY rr.total_revenue DESC) AS revenue_rank
FROM 
    RegionRevenue rr
WHERE 
    rr.total_revenue > 500000
ORDER BY 
    rr.total_revenue DESC;