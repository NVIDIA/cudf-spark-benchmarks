WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        COALESCE(AVG(od.total_revenue), 0) AS average_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    SUM(co.order_count) AS total_orders,
    AVG(co.average_revenue) AS avg_revenue_per_customer,
    (SELECT COUNT(*) FROM RankedSuppliers s WHERE s.supplier_rank <= 5) AS top_suppliers_count
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
WHERE 
    s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
GROUP BY 
    r.r_name
HAVING 
    AVG(co.average_revenue) > (SELECT AVG(average_revenue) FROM CustomerOrders)
ORDER BY 
    total_orders DESC;