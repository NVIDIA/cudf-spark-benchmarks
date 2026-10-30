WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
AggregatedOrders AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(a.total_revenue, 0) AS revenue
    FROM 
        customer c
    LEFT JOIN 
        AggregatedOrders a ON c.c_custkey = a.o_custkey
    WHERE 
        c.c_acctbal > 5000
)
SELECT 
    DISTINCT f.c_custkey,
    f.c_name,
    f.revenue,
    COALESCE(r.s_name, 'No Supplier') AS preferred_supplier
FROM 
    FilteredCustomers f
LEFT JOIN 
    RankedSuppliers r ON f.c_custkey = r.s_suppkey
WHERE 
    f.revenue > 1000 OR r.rank = 1
ORDER BY 
    f.revenue DESC, f.c_name;
