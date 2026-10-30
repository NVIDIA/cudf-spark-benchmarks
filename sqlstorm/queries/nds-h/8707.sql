WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.nation, 
        r.s_suppkey,
        r.s_name,
        r.s_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank = 1
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        os.total_orders,
        os.total_revenue
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
),
NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(cr.total_revenue) AS revenue,
        COUNT(DISTINCT cr.c_custkey) AS customer_count
    FROM 
        CustomerRevenue cr
    JOIN 
        nation n ON cr.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name, 
    n.revenue,
    n.customer_count,
    ts.s_name AS top_supplier_name,
    ts.s_acctbal AS top_supplier_acctbal
FROM 
    NationRevenue n
JOIN 
    TopSuppliers ts ON n.n_name = ts.nation
ORDER BY 
    n.revenue DESC, 
    n.customer_count DESC;
