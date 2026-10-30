WITH RankedSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND
        o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
AggregatedData AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(co.net_revenue) AS total_net_revenue
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    ad.nation,
    ad.region,
    ad.customer_count,
    ad.total_net_revenue,
    CASE 
        WHEN ad.total_net_revenue IS NULL THEN 'No Revenue'
        WHEN ad.total_net_revenue < 1000000 THEN 'Low Revenue'
        ELSE 'High Revenue'
    END AS revenue_category,
    (SELECT COUNT(DISTINCT supplier_rank) FROM RankedSuppliers rs WHERE rs.supplier_rank = 1) AS top_supplier_count
FROM 
    AggregatedData ad
ORDER BY 
    ad.total_net_revenue DESC
LIMIT 10;