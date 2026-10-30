WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), OrderSummary AS (
    SELECT 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_custkey
), CustomerRevenue AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(os.total_revenue, 0) AS total_revenue, 
        os.order_count
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE 
        c.c_acctbal > 1000.00
), SupplierRevenue AS (
    SELECT 
        pd.s_suppkey,
        pd.s_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS supplier_revenue
    FROM 
        SupplierDetails pd
    JOIN 
        partsupp ps ON pd.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        pd.s_suppkey, pd.s_name
)
SELECT 
    cr.c_name, 
    cr.total_revenue AS customer_revenue, 
    sr.s_name AS supplier_name, 
    sr.supplier_revenue
FROM 
    CustomerRevenue cr
JOIN 
    SupplierRevenue sr ON cr.total_revenue < sr.supplier_revenue
ORDER BY 
    cr.total_revenue DESC, 
    sr.supplier_revenue DESC
LIMIT 10;