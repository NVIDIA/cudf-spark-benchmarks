WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
), SupplierOrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), NationalRevenue AS (
    SELECT 
        n.n_name,
        SUM(sos.total_revenue) AS regional_revenue
    FROM 
        Nation n
    LEFT JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    LEFT JOIN 
        SupplierOrderSummary sos ON rs.s_suppkey = sos.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    nr.n_name,
    nr.regional_revenue,
    CASE 
        WHEN nr.regional_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Available'
    END AS revenue_status,
    COALESCE(nr.regional_revenue, 0) AS revenue_with_default
FROM 
    NationalRevenue nr
ORDER BY 
    nr.regional_revenue DESC;
