
WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS supplier_count,
        SUM(s_acctbal) AS total_acctbal,
        AVG(s_acctbal) AS avg_acctbal
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ss.supplier_count,
        ss.total_acctbal,
        ss.avg_acctbal
    FROM 
        nation n
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    INNER JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        l.l_orderkey, o.o_orderdate
),
FinalStats AS (
    SELECT 
        ns.n_name,
        COALESCE(cs.order_count, 0) AS customer_orders,
        COALESCE(cs.total_spent, 0) AS total_spent,
        COALESCE(ds.net_revenue, 0) AS total_revenue,
        RANK() OVER (PARTITION BY ns.n_name ORDER BY COALESCE(ds.net_revenue, 0) DESC) AS revenue_rank
    FROM 
        NationSupplier ns
    LEFT JOIN 
        CustomerOrders cs ON ns.n_nationkey = cs.c_custkey
    LEFT JOIN 
        OrderDetails ds ON ns.n_nationkey = ds.l_orderkey
)
SELECT 
    n.n_name,
    n.supplier_count,
    n.total_acctbal,
    n.avg_acctbal,
    fs.customer_orders,
    fs.total_spent,
    fs.total_revenue,
    fs.revenue_rank
FROM 
    NationSupplier n
LEFT JOIN 
    FinalStats fs ON n.n_name = fs.n_name
WHERE 
    (n.total_acctbal IS NOT NULL AND n.total_acctbal > 10000)
    OR (fs.total_revenue IS NOT NULL AND fs.total_revenue > 5000)
ORDER BY 
    n.n_name, fs.total_revenue DESC;
