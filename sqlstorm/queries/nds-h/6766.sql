WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('Germany', 'France', 'USA')
),
AggregatedSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(o.o_orderkey) AS num_orders
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        l.l_partkey
),
FinalReport AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(a.total_revenue, 0) AS total_revenue,
        COALESCE(a.num_orders, 0) AS num_orders,
        rs.s_name AS top_supplier_name,
        rs.s_acctbal AS top_supplier_acctbal
    FROM 
        part p
    LEFT JOIN 
        AggregatedSales a ON p.p_partkey = a.l_partkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.rank = 1 AND a.total_revenue > 0
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    f.total_revenue,
    f.num_orders,
    f.top_supplier_name,
    f.top_supplier_acctbal
FROM 
    FinalReport f
ORDER BY 
    f.total_revenue DESC
LIMIT 100;