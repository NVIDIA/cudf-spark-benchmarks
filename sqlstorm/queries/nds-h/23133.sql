WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
), 
LargeOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
SupplierOrders AS (
    SELECT 
        rs.s_suppkey,
        lo.o_orderkey,
        lo.total_revenue,
        CASE 
            WHEN lo.total_revenue > 20000 THEN 'High Value'
            ELSE 'Normal'
        END AS order_category
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        LargeOrders lo ON l.l_orderkey = lo.o_orderkey
)
SELECT 
    so.s_suppkey,
    so.order_category,
    SUM(so.total_revenue) AS total_revenue_by_supplier,
    COUNT(DISTINCT so.o_orderkey) AS order_count,
    COUNT(DISTINCT CASE WHEN so.order_category = 'High Value' THEN so.o_orderkey END) AS high_value_order_count
FROM 
    SupplierOrders so
GROUP BY 
    so.s_suppkey, so.order_category
HAVING 
    SUM(so.total_revenue) IS NOT NULL
ORDER BY 
    total_revenue_by_supplier DESC, so.s_suppkey ASC
LIMIT 50;
