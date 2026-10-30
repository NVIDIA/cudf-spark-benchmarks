WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
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
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        SUM(os.total_revenue) AS total_nation_revenue
    FROM 
        OrderSummary os
    JOIN 
        customer c ON os.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name,
    COALESCE(nr.total_nation_revenue, 0) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    RANK() OVER (ORDER BY COALESCE(nr.total_nation_revenue, 0) DESC) AS revenue_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationRevenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY 
    r.r_name, nr.total_nation_revenue
ORDER BY 
    r.r_name;